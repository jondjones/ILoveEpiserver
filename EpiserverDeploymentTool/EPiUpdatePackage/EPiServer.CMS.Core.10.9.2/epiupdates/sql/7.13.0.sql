--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7011)
				select 0, 'Already correct database version'
            else if (@ver = 7010)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO
PRINT N'Creating [dbo].[UriPartsTable]...';


GO
CREATE TYPE [dbo].[UriPartsTable] AS TABLE (
    [Host] NVARCHAR (255)  NOT NULL,
    [Path] NVARCHAR (2048) NOT NULL);


GO
PRINT N'Creating [dbo].[tblMappedIdentity]...';


GO
CREATE TABLE [dbo].[tblMappedIdentity] (
    [pkID]                   INT              IDENTITY (1, 1) NOT NULL,
    [Provider]               NVARCHAR (255)   NOT NULL,
    [ProviderUniqueId]       NVARCHAR (2048)  NOT NULL,
    [ContentGuid]            UNIQUEIDENTIFIER NOT NULL,
    [ExistingContentId]      INT              NULL,
    [ExistingCustomProvider] BIT              NULL,
    CONSTRAINT [PK_tblMappedIdentity] PRIMARY KEY NONCLUSTERED ([pkID] ASC)
);


GO
PRINT N'Creating [dbo].[tblMappedIdentity].[IDX_tblMappedIdentity_Provider]...';


GO
CREATE CLUSTERED INDEX [IDX_tblMappedIdentity_Provider]
    ON [dbo].[tblMappedIdentity]([Provider] ASC, [ProviderUniqueId] ASC);


GO
PRINT N'Creating [dbo].[tblMappedIdentity].[IDX_tblMappedIdentity_ContentGuid]...';


GO
CREATE UNIQUE NONCLUSTERED INDEX [IDX_tblMappedIdentity_ContentGuid]
    ON [dbo].[tblMappedIdentity]([ContentGuid] ASC);


GO
PRINT N'Creating [dbo].[tblMappedIdentity].[IDX_tblMappedIdentity_ExternalId]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblMappedIdentity_ExternalId]
    ON [dbo].[tblMappedIdentity]([ExistingContentId] ASC, [ExistingCustomProvider] ASC);


GO
PRINT N'Creating DF_tblMappedIdentity_ContentGuid...';


GO
ALTER TABLE [dbo].[tblMappedIdentity]
    ADD CONSTRAINT [DF_tblMappedIdentity_ContentGuid] DEFAULT (NEWID()) FOR [ContentGuid];


GO

PRINT N'Creating [dbo].[netMappedIdentityDelete]...';


GO
CREATE PROCEDURE [dbo].[netMappedIdentityDelete]
	@Provider NVARCHAR(255),
	@ProviderUniqueId NVARCHAR(2048)
AS
BEGIN
	SET NOCOUNT ON;

	DELETE
	FROM tblMappedIdentity
	WHERE tblMappedIdentity.Provider = @Provider AND tblMappedIdentity.ProviderUniqueId = @ProviderUniqueId
END
GO
PRINT N'Creating [dbo].[netMappedIdentityForProvider]...';


GO
CREATE PROCEDURE [dbo].[netMappedIdentityForProvider]
	@Provider NVARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT MI.pkID AS ContentId, MI.Provider, MI.ProviderUniqueId, MI.ContentGuid, Mi.ExistingContentId, MI.ExistingCustomProvider
	FROM tblMappedIdentity AS MI
	WHERE MI.Provider = @Provider
END
GO
PRINT N'Creating [dbo].[netMappedIdentityGetByGuid]...';


GO
CREATE PROCEDURE [dbo].[netMappedIdentityGetByGuid]
	@ContentGuids dbo.GuidParameterTable READONLY
AS
BEGIN
	SET NOCOUNT ON;

	SELECT MI.pkID AS ContentId, MI.Provider, MI.ProviderUniqueId, MI.ContentGuid, MI.ExistingContentId, MI.ExistingCustomProvider
	FROM tblMappedIdentity AS MI INNER JOIN @ContentGuids AS EI ON MI.ContentGuid = EI.Id
END
GO
PRINT N'Creating [dbo].[netMappedIdentityGetById]...';


GO
CREATE PROCEDURE [dbo].[netMappedIdentityGetById]
	@InternalIds dbo.ContentReferenceTable READONLY
AS
BEGIN
	SET NOCOUNT ON;

	SELECT MI.pkID AS ContentId, MI.Provider, MI.ProviderUniqueId, MI.ContentGuid, MI.ExistingContentId, MI.ExistingCustomProvider
	FROM tblMappedIdentity AS MI 
	INNER JOIN @InternalIds AS EI ON (MI.pkID = EI.ID AND MI.Provider = EI.Provider)
	UNION (SELECT MI2.pkID AS ContentId, MI2.Provider, MI2.ProviderUniqueId, MI2.ContentGuid, MI2.ExistingContentId, MI2.ExistingCustomProvider
		FROM tblMappedIdentity AS MI2
		INNER JOIN @InternalIds AS EI2 ON (MI2.ExistingContentId = EI2.ID)
		WHERE ((MI2.ExistingCustomProvider = 1 AND MI2.Provider = EI2.Provider) OR (MI2.ExistingCustomProvider IS NULL AND EI2.Provider IS NULL)))
	END
GO
PRINT N'Creating [dbo].[netMappedIdentityGetOrCreate]...';


GO
CREATE PROCEDURE [dbo].[netMappedIdentityGetOrCreate]
	@ExternalIds dbo.UriPartsTable READONLY,
	@CreateIfMissing BIT
AS
BEGIN
	SET NOCOUNT ON;

	--Create first missing entries
	IF @CreateIfMissing = 1
	BEGIN
		MERGE tblMappedIdentity AS TARGET
		USING @ExternalIds AS Source
		ON (Target.Provider = Source.Host AND Target.ProviderUniqueId = Source.Path)
		WHEN NOT MATCHED BY Target THEN
			INSERT (Provider, ProviderUniqueId)
			VALUES (Source.Host, Source.Path);
	END

	SELECT MI.pkID AS ContentId, MI.Provider, MI.ProviderUniqueId, MI.ContentGuid, MI.ExistingContentId, MI.ExistingCustomProvider
	FROM tblMappedIdentity AS MI INNER JOIN @ExternalIds AS EI ON MI.ProviderUniqueId = EI.Path
	WHERE MI.Provider = EI.Host
END
GO
PRINT N'Creating [dbo].[netMappedIdentityListProviders]...';


GO
CREATE PROCEDURE [dbo].[netMappedIdentityListProviders]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT DISTINCT Provider
	FROM tblMappedIdentity 
END
GO
PRINT N'Creating [dbo].[netMappedIdentityMapContent]...';


GO
CREATE PROCEDURE [dbo].[netMappedIdentityMapContent]
	@Provider NVARCHAR(255),
	@ProviderUniqueId NVARCHAR(2048),
	@ExistingContentId INT,
	@ExistingCustomProvider BIT = NULL,
	@ContentGuid UniqueIdentifier
AS
BEGIN
	SET NOCOUNT ON;

	--Return 1 if already exist entry
	IF EXISTS(SELECT 1 FROM tblMappedIdentity WHERE Provider=@Provider AND ProviderUniqueId = @ProviderUniqueId)
	BEGIN
		RETURN 1
	END

	INSERT INTO tblMappedIdentity(Provider, ProviderUniqueId, ContentGuid, ExistingContentId, ExistingCustomProvider) 
		VALUES(@Provider, @ProviderUniqueId, @ContentGuid, @ExistingContentId, @ExistingCustomProvider)

	RETURN 0
END
GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7011
GO

PRINT N'Update complete.';


GO

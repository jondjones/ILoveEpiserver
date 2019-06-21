--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7020)
				select 0, 'Already correct database version'
            else if (@ver = 7019)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO
PRINT N'Creating [dbo].[HostDefinitionTable]...';


GO
CREATE TYPE [dbo].[HostDefinitionTable] AS TABLE 
(
    [Name]     VARCHAR(MAX)  NOT NULL, 
    [Type]     INT           NULL,
    [Language] VARCHAR (50)  NULL,
    [Https]    BIT           NULL
); 


GO
PRINT N'Creating [dbo].[tblHostDefinition]...';


GO
CREATE TABLE [dbo].[tblHostDefinition] (
    [pkID]     INT           IDENTITY (1, 1) NOT NULL,
    [fkSiteID] INT           NOT NULL,
    [Name]     VARCHAR (MAX) NOT NULL,
    [Type]     INT           NOT NULL,
    [Language] VARCHAR (50)  NULL,
    [Https]	   BIT           NULL, 
    CONSTRAINT [PK_tblHostDefinition] PRIMARY KEY CLUSTERED ([pkID] ASC)
);


GO
PRINT N'Creating [dbo].[tblHostDefinition].[IX_tblHostDefinition_fkID]...';


GO
CREATE NONCLUSTERED INDEX [IX_tblHostDefinition_fkID]
    ON [dbo].[tblHostDefinition]([fkSiteID] ASC);


GO
PRINT N'Creating [dbo].[tblSiteDefinition]...';


GO
CREATE TABLE [dbo].[tblSiteDefinition] (
    [pkID]           INT              IDENTITY (1, 1) NOT NULL,
    [UniqueId]       UNIQUEIDENTIFIER NOT NULL,
    [Name]           NVARCHAR (255)   NOT NULL,
    [StartPage]      VARCHAR (255)    NULL,
    [SiteUrl]        VARCHAR (MAX)    NULL,
    [SiteAssetsRoot] VARCHAR (255)    NULL,
    CONSTRAINT [PK_tblSiteDefinition] PRIMARY KEY CLUSTERED ([pkID] ASC)
);


GO
PRINT N'Creating [dbo].[tblSiteDefinition].[IX_tblSiteDefinition_UniqueId]...';


GO
CREATE NONCLUSTERED INDEX [IX_tblSiteDefinition_UniqueId]
    ON [dbo].[tblSiteDefinition]([UniqueId] ASC);


GO
PRINT N'Creating unnamed constraint on [dbo].[tblHostDefinition]...';


GO
ALTER TABLE [dbo].[tblHostDefinition]
    ADD DEFAULT 0 FOR [Type];


GO
PRINT N'Creating [dbo].[FK_tblHostDefinition_tblSiteDefinition]...';


GO
ALTER TABLE [dbo].[tblHostDefinition] WITH NOCHECK
    ADD CONSTRAINT [FK_tblHostDefinition_tblSiteDefinition] FOREIGN KEY ([fkSiteID]) REFERENCES [dbo].[tblSiteDefinition] ([pkID]) ON DELETE CASCADE;


GO
PRINT N'Creating [dbo].[netSiteDefinitionDelete]...';


GO
CREATE PROCEDURE [dbo].[netSiteDefinitionDelete]
(
	@UniqueId		uniqueidentifier
)
AS
BEGIN
	SET NOCOUNT ON

	DELETE FROM tblSiteDefinition WHERE UniqueId = @UniqueId
END
GO
PRINT N'Creating [dbo].[netSiteDefinitionList]...';


GO
CREATE PROCEDURE [dbo].[netSiteDefinitionList]
AS
BEGIN
	SELECT UniqueId, Name, SiteUrl, StartPage, SiteAssetsRoot FROM tblSiteDefinition

	SELECT site.[UniqueId] AS SiteId, host.[Name], host.[Type], host.[Language], host.[Https]
	FROM tblHostDefinition host
	INNER JOIN tblSiteDefinition site ON site.pkID = host.fkSiteID

END
GO
PRINT N'Creating [dbo].[netSiteDefinitionSave]...';


GO
CREATE PROCEDURE [dbo].[netSiteDefinitionSave]
(
	@UniqueId uniqueidentifier = NULL OUTPUT,
	@Name nvarchar(255),
	@SiteUrl varchar(MAX),
	@StartPage varchar(255),
	@SiteAssetsRoot varchar(255) = NULL,
	@Hosts dbo.HostDefinitionTable READONLY
)
AS
BEGIN
	DECLARE @SiteID int
	
	IF (@UniqueId IS NULL OR @UniqueId = CAST(0x0 AS uniqueidentifier))
		SET @UniqueId = NEWID()
	ELSE -- If UniqueId is set we must first check if it has been saved before
		SELECT @SiteID = pkID FROM tblSiteDefinition WHERE UniqueId = @UniqueId

	IF (@SiteID IS NULL) 
	BEGIN
		INSERT INTO tblSiteDefinition 
		(
			UniqueId,
			Name,
			SiteUrl,
			StartPage,
			SiteAssetsRoot
		) 
		VALUES
		(
			@UniqueId,
			@Name,
			@SiteUrl,
			@StartPage,
			@SiteAssetsRoot
		)
		SET @SiteID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE tblSiteDefinition SET 
			UniqueId=@UniqueId,
			Name = @Name,
			SiteUrl = @SiteUrl,
			StartPage = @StartPage,
			SiteAssetsRoot = @SiteAssetsRoot
		WHERE
			pkID = @SiteID
		
	END

	-- Site hosts
	MERGE tblHostDefinition AS Target
    USING @Hosts AS Source
    ON (Target.Name = Source.Name AND Target.fkSiteID=@SiteID)
    WHEN MATCHED THEN 
        UPDATE SET fkSiteID = @SiteID, Name = Source.Name, Type = Source.Type, Language = Source.Language, Https = Source.Https
	WHEN NOT MATCHED BY Source AND Target.fkSiteID = @SiteID THEN
		DELETE
	WHEN NOT MATCHED BY Target THEN
		INSERT (fkSiteID, Name, Type, Language, Https)
		VALUES (@SiteID, Source.Name, Source.Type, Source.Language, Source.Https);

END
GO

-- BEGIN - Manually created update

-- Ensure that the views for the site and host definition stores has been created
IF (EXISTS(SELECT * FROM sys.views WHERE name = 'VW_EPiServer.Web.SiteDefinition') AND
    EXISTS(SELECT * FROM sys.views WHERE name = 'VW_EPiServer.Web.HostDefinition'))
BEGIN
	PRINT N'Migrating site definitions...';

	INSERT INTO tblSiteDefinition(UniqueId, Name, StartPage, SiteUrl, SiteAssetsRoot)
	SELECT s.ExternalId AS UniqueId, s.Name, s.StartPage, s.SiteUrl, s.SiteAssetsRoot
	FROM [VW_EPiServer.Web.SiteDefinition] s

	-- As the Type column was recently introduced it may not be present in the HostDefintion view
	DECLARE @TypeColumn nvarchar(50)
	IF EXISTS (SELECT * FROM sys.columns WHERE name='Type' AND object_id = (select top 1 object_id from sys.views where name='VW_EPiServer.Web.HostDefinition'))
		SET @TypeColumn = 'ISNULL(h.[Type], 0)'
	ELSE
		SET @TypeColumn = '0'

	EXEC ('INSERT INTO tblHostDefinition(fkSiteID, Name, Type, Language)
		   SELECT s2.pkID as fkSiteID, h.[Name], ' +@TypeColumn+ ' AS ''Type'', h.[Language] 
		   FROM [VW_EPiServer.Web.HostDefinition] h
		   INNER JOIN tblBigTableReference r ON h.StoreId = r.RefIdValue AND PropertyName = ''Hosts''
		   INNER JOIN [VW_EPiServer.Web.SiteDefinition] s1 ON s1.StoreId = r.pkId
		   INNER JOIN tblSiteDefinition s2 ON s1.ExternalId = s2.UniqueId
		  ')
END 
GO

-- END - Manually created update

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';
GO

ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7020

GO
PRINT N'Update complete.';
GO

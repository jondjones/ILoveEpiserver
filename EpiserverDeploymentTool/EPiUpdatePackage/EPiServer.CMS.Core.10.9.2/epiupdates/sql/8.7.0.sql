--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7019)
				select 0, 'Already correct database version'
            else if (@ver = 7018)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery


GO
PRINT N'Dropping [dbo].[DF_tblMappedIdentity_ContentGuid]...';


GO
ALTER TABLE [dbo].[tblMappedIdentity] DROP CONSTRAINT [DF_tblMappedIdentity_ContentGuid];


GO
PRINT N'Starting rebuilding table [dbo].[tblMappedIdentity]...';


GO
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

CREATE TABLE [dbo].[tmp_ms_xx_tblMappedIdentity] (
    [pkID]                   INT              IDENTITY (1, 1) NOT NULL,
    [Provider]               NVARCHAR (255)   NOT NULL,
    [ProviderUniqueId]       NVARCHAR (450)   NOT NULL,
    [ContentGuid]            UNIQUEIDENTIFIER CONSTRAINT [DF_tblMappedIdentity_ContentGuid] DEFAULT (NEWID()) NOT NULL,
    [ExistingContentId]      INT              NULL,
    [ExistingCustomProvider] BIT              NULL,
    CONSTRAINT [tmp_ms_xx_constraint_PK_tblMappedIdentity] PRIMARY KEY NONCLUSTERED ([pkID] ASC)
);

CREATE CLUSTERED INDEX [tmp_ms_xx_index_IDX_tblMappedIdentity_ProviderUniqueId]
    ON [dbo].[tmp_ms_xx_tblMappedIdentity]([ProviderUniqueId] ASC);

IF EXISTS (SELECT TOP 1 1 
           FROM   [dbo].[tblMappedIdentity])
    BEGIN
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_tblMappedIdentity] ON;
        INSERT INTO [dbo].[tmp_ms_xx_tblMappedIdentity] ([ProviderUniqueId], [pkID], [Provider], [ContentGuid], [ExistingContentId], [ExistingCustomProvider])
        SELECT   [ProviderUniqueId],
                 [pkID],
                 [Provider],
                 [ContentGuid],
                 [ExistingContentId],
                 [ExistingCustomProvider]
        FROM     [dbo].[tblMappedIdentity]
        ORDER BY [ProviderUniqueId] ASC;
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_tblMappedIdentity] OFF;
    END

DROP TABLE [dbo].[tblMappedIdentity];

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_tblMappedIdentity]', N'tblMappedIdentity';

EXECUTE sp_rename N'[dbo].[tblMappedIdentity].[tmp_ms_xx_index_IDX_tblMappedIdentity_ProviderUniqueId]', N'IDX_tblMappedIdentity_ProviderUniqueId', N'INDEX';

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_constraint_PK_tblMappedIdentity]', N'PK_tblMappedIdentity', N'OBJECT';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


GO
PRINT N'Creating [dbo].[tblMappedIdentity].[IDX_tblMappedIdentity_Provider]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblMappedIdentity_Provider]
    ON [dbo].[tblMappedIdentity]([Provider] ASC);


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
PRINT N'Creating [dbo].[netMappedIdentityDeleteItems]...';


GO
CREATE PROCEDURE [dbo].[netMappedIdentityDeleteItems]
	@ContentGuids dbo.GuidParameterTable READONLY
AS
BEGIN
	SET NOCOUNT ON;

	DELETE mi 
	FROM tblMappedIdentity mi
	INNER JOIN @ContentGuids cg ON mi.ContentGuid = cg.Id
END


GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7019
GO
PRINT N'Update complete.';


GO

--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7013)
				select 0, 'Already correct database version'
            else if (@ver = 7012)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO
PRINT N'Creating [dbo].[tblTaskInformation]...';


GO
CREATE TABLE [dbo].[tblTaskInformation] (
    [pkId]               BIGINT           NOT NULL,
    [Row]                INT              NOT NULL,
    [StoreName]          NVARCHAR (375)   NOT NULL,
    [ItemType]           NVARCHAR (2000)  NOT NULL,
    [Boolean01]          BIT              NULL,
    [Boolean02]          BIT              NULL,
    [Integer01]          INT              NULL,
    [Long01]             BIGINT           NULL,
    [DateTime01]         DATETIME         NULL,
    [Guid01]             UNIQUEIDENTIFIER NULL,
    [Float01]            FLOAT (53)       NULL,
    [String01]           NVARCHAR (MAX)   NULL,
    [Indexed_Integer01]  INT              NULL,
    [Indexed_DateTime01] DATETIME         NULL,
    [Indexed_DateTime02] DATETIME         NULL,
    [Indexed_Guid01]     UNIQUEIDENTIFIER NULL,
    [Indexed_String01]   NVARCHAR (450)   NULL,
    [Indexed_String02]   NVARCHAR (450)   NULL,
    CONSTRAINT [PK_tblTaskInformation] PRIMARY KEY CLUSTERED ([pkId] ASC, [Row] ASC)
);


GO
PRINT N'Creating [dbo].[tblTaskInformation].[IDX_tblTaskInformation_StoreName]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblTaskInformation_StoreName]
    ON [dbo].[tblTaskInformation]([StoreName] ASC);


GO
PRINT N'Creating [dbo].[tblTaskInformation].[IDX_tblTaskInformation_Indexed_Integer01]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblTaskInformation_Indexed_Integer01]
    ON [dbo].[tblTaskInformation]([Indexed_Integer01] ASC);


GO
PRINT N'Creating [dbo].[tblTaskInformation].[IDX_tblTaskInformation_Indexed_DateTime01]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblTaskInformation_Indexed_DateTime01]
    ON [dbo].[tblTaskInformation]([Indexed_DateTime01] ASC);


GO
PRINT N'Creating [dbo].[tblTaskInformation].[IDX_tblTaskInformation_Indexed_DateTime02]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblTaskInformation_Indexed_DateTime02]
    ON [dbo].[tblTaskInformation]([Indexed_DateTime02] ASC);


GO
PRINT N'Creating [dbo].[tblTaskInformation].[IDX_tblTaskInformation_Indexed_Guid01]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblTaskInformation_Indexed_Guid01]
    ON [dbo].[tblTaskInformation]([Indexed_Guid01] ASC);


GO
PRINT N'Creating [dbo].[tblTaskInformation].[IDX_tblTaskInformation_Indexed_String01]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblTaskInformation_Indexed_String01]
    ON [dbo].[tblTaskInformation]([Indexed_String01] ASC);


GO
PRINT N'Creating [dbo].[tblTaskInformation].[IDX_tblTaskInformation_Indexed_String02]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblTaskInformation_Indexed_String02]
    ON [dbo].[tblTaskInformation]([Indexed_String02] ASC);


GO
PRINT N'Creating tblTaskInformation_Row...';


GO
ALTER TABLE [dbo].[tblTaskInformation]
    ADD CONSTRAINT [tblTaskInformation_Row] DEFAULT (1) FOR [Row];


GO
PRINT N'Creating FK_tblTaskInformation_tblBigTableIdentity...';


GO
ALTER TABLE [dbo].[tblTaskInformation] WITH NOCHECK
    ADD CONSTRAINT [FK_tblTaskInformation_tblBigTableIdentity] FOREIGN KEY ([pkId]) REFERENCES [dbo].[tblBigTableIdentity] ([pkId]);


GO
PRINT N'Creating CH_tblTaskInformation...';


GO
ALTER TABLE [dbo].[tblTaskInformation] WITH NOCHECK
    ADD CONSTRAINT [CH_tblTaskInformation] CHECK ([Row]>=1);


GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7013
GO

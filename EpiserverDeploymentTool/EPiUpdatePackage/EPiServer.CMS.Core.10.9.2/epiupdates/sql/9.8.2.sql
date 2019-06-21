--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7035)
				select 0, 'Already correct database version'
            else if (@ver = 7034)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
GO

PRINT N'Creating [dbo].[LongParameterTable]...';
GO

CREATE TYPE [dbo].[LongParameterTable] AS TABLE (
	Id BIGINT
);
GO

PRINT N'Creating [dbo].[netActivityLogCommentListMany]...';
GO

CREATE PROCEDURE [dbo].[netActivityLogCommentListMany]
(
	@EntryIds AS LongParameterTable READONLY
)
AS            
BEGIN
	SELECT alc.* FROM [tblActivityLogComment] alc
	JOIN @EntryIds ids ON alc.EntryId = ids.Id
	ORDER BY alc.pkID DESC
END
GO

ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7035
GO

PRINT N'Update complete.';
GO

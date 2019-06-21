--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7036)
				select 0, 'Already correct database version'
            else if (@ver = 7035)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
GO

PRINT 'Fix new namespaces for notification jobs'
IF NOT EXISTS(SELECT * FROM tblScheduledItem WHERE TypeName = 'EPiServer.Notification.Internal.NotificationDispatcherJob')
BEGIN
	PRINT 'Migrating to new namespace: EPiServer.Notification.Internal.NotificationDispatcherJob'
	UPDATE tblScheduledItem SET TypeName = 'EPiServer.Notification.Internal.NotificationDispatcherJob' WHERE TypeName = 'EPiServer.Notification.NotificationDispatcherJob'
END
ELSE
BEGIN
	DECLARE @OldId UNIQUEIDENTIFIER
	SET @OldId  = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Notification.NotificationDispatcherJob')
	IF NOT @OldId IS NULL
	BEGIN
		PRINT 'Removing duplicate'
		DELETE FROM tblScheduledItemLog WHERE fkScheduledItemId = @OldId
		DELETE FROM tblScheduledItem WHERE pkID = @OldId
	END
	ELSE
		PRINT 'No duplicates'
END

PRINT 'Migrating to new namespace: EPiServer.Notification.Internal.NotificationMessageTruncateJob'
UPDATE tblScheduledItem SET TypeName = 'EPiServer.Notification.Internal.NotificationMessageTruncateJob' WHERE TypeName = 'EPiServer.Notification.NotificationMessageTruncateJob'
GO

PRINT N'Altering [dbo].[netReportExpiredPages]...';
GO

ALTER PROCEDURE [dbo].[netReportExpiredPages](
       @PageID int,
       @StartDate datetime,
       @StopDate datetime,
       @Language int = -1,
       @PageSize int,
       @PageNumber int = 0,
       @SortColumn varchar(40) = 'StopPublish',
       @SortDescending bit = 0,
       @PublishedByName nvarchar(256) = null)
   AS
   BEGIN
       SET NOCOUNT ON;
       
       DECLARE @OrderBy NVARCHAR(MAX)
       SET @OrderBy =
           CASE @SortColumn
               WHEN 'PageName' THEN 'tblPageLanguage.Name'
               WHEN 'StartPublish' THEN 'tblPageLanguage.StartPublish'
               WHEN 'StopPublish' THEN 'tblPageLanguage.StopPublish'
               WHEN 'ChangedBy' THEN 'tblPageLanguage.ChangedByName'
               WHEN 'Saved' THEN 'tblPageLanguage.Saved'
               WHEN 'Language' THEN 'tblLanguageBranch.LanguageID'
               WHEN 'PageTypeName' THEN 'tblPageType.Name'
           END
       IF(@SortDescending = 1)
           SET @OrderBy = @OrderBy + ' DESC'
   
       DECLARE @sql NVARCHAR(MAX)
       SET @sql = 'WITH PageCTE AS
       (
           SELECT ROW_NUMBER() OVER(ORDER BY ' 
               + @OrderBy 
               + ') AS rownum,
           tblPageLanguage.fkPageID, tblPageLanguage.Version AS PublishedVersion, count(tblPageLanguage.fkPageID) over () as totcount                        
           FROM tblPageLanguage 
           INNER JOIN tblTree ON tblTree.fkChildID=tblPageLanguage.fkPageID 
           INNER JOIN tblPage ON tblPage.pkID=tblPageLanguage.fkPageID 
           INNER JOIN tblPageType ON tblPageType.pkID=tblPage.fkPageTypeID 
           INNER JOIN tblLanguageBranch ON tblLanguageBranch.pkID=tblPageLanguage.fkLanguageBranchID 
           WHERE 
			(tblTree.fkParentID = @PageID OR (tblPageLanguage.fkPageID = @PageID AND tblTree.NestingLevel = 1))
           AND 
			(@StartDate IS NULL OR tblPageLanguage.StopPublish>@StartDate)
           AND
			(@StopDate IS NULL OR tblPageLanguage.StopPublish<@StopDate)
           AND
			(@Language = -1 OR tblPageLanguage.fkLanguageBranchID = @Language)
           AND 
			tblPage.ContentType = 0
           AND 
			tblPageLanguage.Status=4
           AND 
			(@PublishedByName IS NULL OR tblPageLanguage.ChangedByName = @PublishedByName)
       )
       SELECT PageCTE.fkPageID, PageCTE.PublishedVersion, PageCTE.rownum, totcount
       FROM PageCTE
       WHERE rownum > @PageSize * (@PageNumber)
       AND rownum <= @PageSize * (@PageNumber+1)
       ORDER BY rownum'
       
       EXEC sp_executesql @sql, N'@PageID int, @StartDate datetime, @StopDate datetime, @Language int, @PublishedByName nvarchar(256), @PageSize int, @PageNumber int',
           @PageID = @PageID, 
           @StartDate = @StartDate, 
           @StopDate = @StopDate, 
           @Language = @Language, 
           @PublishedByName = @PublishedByName, 
           @PageSize = @PageSize, 
           @PageNumber = @PageNumber
   END
GO


PRINT N'Altering [dbo].[netReportReadyToPublish]...';
GO
 
ALTER PROCEDURE [dbo].netReportReadyToPublish(
	@PageID int,
	@StartDate datetime,
	@StopDate datetime,
	@Language int = -1,
	@ChangedByUserName nvarchar(256) = null,
	@PageSize int,
	@PageNumber int = 0,
	@SortColumn varchar(40) = 'PageName',
	@SortDescending bit = 0,
	@IsReadyToPublish bit = 1)
AS
BEGIN
	SET NOCOUNT ON;
	WITH PageCTE AS
                    (
                        SELECT ROW_NUMBER() OVER(ORDER BY 
							-- Page Name Sorting
							CASE WHEN @SortColumn = 'PageName' AND @SortDescending = 1 THEN tblWorkPage.Name END DESC,
							CASE WHEN @SortColumn = 'PageName' THEN tblWorkPage.Name END ASC,
							-- Saved Sorting
							CASE WHEN @SortColumn = 'Saved' AND @SortDescending = 1 THEN tblWorkPage.Saved END DESC,
							CASE WHEN @SortColumn = 'Saved' THEN tblWorkPage.Saved END ASC,
							-- StartPublish Sorting
							CASE WHEN @SortColumn = 'StartPublish' AND @SortDescending = 1 THEN tblWorkPage.StartPublish END DESC,
							CASE WHEN @SortColumn = 'StartPublish' THEN tblWorkPage.StartPublish END ASC,
							-- Changed By Sorting
							CASE WHEN @SortColumn = 'ChangedBy' AND @SortDescending = 1 THEN tblWorkPage.ChangedByName END DESC,
							CASE WHEN @SortColumn = 'ChangedBy' THEN tblWorkPage.ChangedByName END ASC,
							-- Language Sorting
							CASE WHEN @SortColumn = 'Language' AND @SortDescending = 1 THEN tblLanguageBranch.LanguageID END DESC,
							CASE WHEN @SortColumn = 'Language' THEN tblLanguageBranch.LanguageID END ASC
							, 
							tblWorkPage.pkID ASC
                        ) AS rownum,
                        tblWorkPage.fkPageID, count(tblWorkPage.fkPageID) over () as totcount,
                        tblWorkPage.pkID as versionId
                        FROM tblWorkPage 
                        INNER JOIN tblTree ON tblTree.fkChildID=tblWorkPage.fkPageID 
                        INNER JOIN tblPage ON tblPage.pkID=tblWorkPage.fkPageID 
						INNER JOIN tblLanguageBranch ON tblLanguageBranch.pkID=tblWorkPage.fkLanguageBranchID 
                        WHERE 
							(tblTree.fkParentID=@PageID OR (tblWorkPage.fkPageID=@PageID AND tblTree.NestingLevel = 1 ))
                        AND
							(@ChangedByUserName IS NULL OR tblWorkPage.ChangedByName = @ChangedByUserName)
                        AND
							tblPage.ContentType = 0
                        AND
							(@Language = -1 OR tblWorkPage.fkLanguageBranchID = @Language)
                        AND 
							(@StartDate IS NULL OR tblWorkPage.Saved > @StartDate)
                        AND
							(@StopDate IS NULL OR tblWorkPage.Saved < @StopDate)
                        AND
							(tblWorkPage.ReadyToPublish = @IsReadyToPublish AND tblWorkPage.HasBeenPublished = 0)
                    )
                    SELECT PageCTE.fkPageID, PageCTE.rownum, totcount, PageCTE.versionId
                    FROM PageCTE
                    WHERE rownum > @PageSize * (@PageNumber)
                    AND rownum <= @PageSize * (@PageNumber+1)
                    ORDER BY rownum
	END
GO



ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7036
GO

PRINT N'Update complete.';
GO

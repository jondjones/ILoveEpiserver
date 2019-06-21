--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7044)
				select 0, 'Already correct database version'
            else if (@ver = 7043)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
GO
PRINT N'Dropping [dbo].[netChangeLogGetRowsBackwards]...';

GO
DROP PROCEDURE [dbo].[netChangeLogGetRowsBackwards];


GO
PRINT N'Dropping [dbo].[netChangeLogGetRowsForwards]...';

GO
DROP PROCEDURE [dbo].[netChangeLogGetRowsForwards];


GO
PRINT N'Creating [dbo].[tblActivityArchive]...';

GO
CREATE TABLE [dbo].[tblActivityArchive] (
    [pkID]       BIGINT         NOT NULL,
    [LogData]    NVARCHAR (MAX) NULL,
    [ChangeDate] DATETIME       NOT NULL,
    [Type]       NVARCHAR (50)  NOT NULL,
    [Action]     INT            NOT NULL,
    [ChangedBy]  NVARCHAR (255) NOT NULL,
    [Deleted]    BIT            NOT NULL,
    CONSTRAINT [PK_tblActivityArchive] PRIMARY KEY CLUSTERED ([pkID] ASC)
);


GO
PRINT N'Creating [dbo].[DF_tblActivityArchive_Action]...';


GO
ALTER TABLE [dbo].[tblActivityArchive]
    ADD CONSTRAINT [DF_tblActivityArchive_Action] DEFAULT (0) FOR [Action];


GO
PRINT N'Creating unnamed constraint on [dbo].[tblActivityArchive]...';


GO
ALTER TABLE [dbo].[tblActivityArchive]
    ADD DEFAULT (0) FOR [Deleted];


GO
PRINT N'Creating [dbo].[completeActivityLog]...';


GO

CREATE VIEW [dbo].[completeActivityLog]
	AS 
SELECT [pkID], [LogData], [ChangeDate], [Type], [Action], [ChangedBy], [Deleted] FROM [tblActivityArchive]
UNION ALL
SELECT [pkID], [LogData], [ChangeDate], [Type], [Action], [ChangedBy], [Deleted] FROM [tblActivityLog]

GO
PRINT N'Altering [dbo].[netActivityLogTruncate]...';

GO
ALTER PROCEDURE [dbo].[netActivityLogTruncate]
(
	@Archive BIT,
	@MaxRows BIGINT,
	@BeforeEntry BIGINT = NULL,
	@CreatedBefore DATETIME = NULL,
	@PreservedRelation NVARCHAR(255) = NULL
)
AS
BEGIN
	DECLARE @paramList NVARCHAR(4000)
	DECLARE @sql NVARCHAR(MAX) 
	DECLARE @PreservedRelationLike NVARCHAR(256) = @PreservedRelation

	SET @sql = 'DELETE TOP(@MaxRows) L'

	IF (@Archive != 0)
		SET @sql += ' OUTPUT DELETED.[pkID], DELETED.[LogData], DELETED.[ChangeDate], DELETED.[Type], DELETED.[Action], DELETED.[ChangedBy], DELETED.Deleted
				INTO [dbo].[tblActivityArchive]([pkID], [LogData], [ChangeDate], [Type], [Action], [ChangedBy], [Deleted])'

	SET @sql += ' FROM [dbo].[tblActivityLog] AS L'

	IF (@PreservedRelation IS NOT NULL)
		SET @sql += ' LEFT OUTER JOIN [dbo].[tblActivityLogAssociation] AS A ON L.pkID = A.[To]'

	SET @sql += ' WHERE 1=1'

	IF (@BeforeEntry IS NOT NULL)
		SET @sql += ' AND L.[pkID] < @BeforeEntry'

	IF (@CreatedBefore IS NOT NULL)
		SET @sql += ' AND L.[ChangeDate] < @CreatedBefore'

	IF (@PreservedRelation IS NOT NULL)
	BEGIN
		SET @PreservedRelationLike += '%'
		SET @sql += ' AND ((A.[From] IS NULL OR A.[From] NOT LIKE @PreservedRelationLike) AND (L.RelatedItem IS NULL OR L.RelatedItem NOT LIKE @PreservedRelationLike))'
	END

	SET @paramList = '@MaxRows BIGINT,
                      @BeforeEntry BIGINT,
	                  @CreatedBefore DATETIME,
                      @PreservedRelationLike NVARCHAR(255)'

	EXEC sp_executesql @sql, @paramList, @MaxRows, @BeforeEntry, @CreatedBefore, @PreservedRelationLike

	RETURN @@ROWCOUNT
END

GO
PRINT N'Creating [dbo].[netActivityLogTruncateArchive]...';
GO
CREATE PROCEDURE [dbo].[netActivityLogTruncateArchive]
(
	@MaxRows BIGINT,
	@CreatedBefore DATETIME
)
AS
BEGIN	

	DELETE TOP(@MaxRows) 
	FROM [tblActivityArchive] 
	WHERE ChangeDate < @CreatedBefore

	RETURN @@ROWCOUNT
END

GO
PRINT N'Creating [dbo].[netActvitiyLogList]...';


GO
CREATE PROCEDURE [dbo].[netActvitiyLogList]
(
	@from 	                 DATETIME = NULL,
	@to	                     DATETIME = NULL,
	@type 					 [nvarchar](255) = NULL,
	@action 				 INT = NULL,
	@changedBy				 [nvarchar](255) = NULL,
	@startSequence			 BIGINT = NULL,
	@maxRows				 BIGINT,
	@archived				 BIT = 0,
	@deleted				 BIT = 0,
	@order					 INT = 0
)
AS
BEGIN
	DECLARE @paramList NVARCHAR(4000)
	DECLARE @sql NVARCHAR(MAX) 

	SET @sql = 'SELECT TOP(@maxRows) [pkID], [LogData], [ChangeDate], [Type], [Action], [ChangedBy], [Deleted]'

	IF @archived = 0
		SET @sql += ', [RelatedItem] FROM dbo.[tblActivityLog]' + CHAR(13);
	ELSE
		SET @sql += ', '''' AS [RelatedItem] FROM [completeActivityLog]' + CHAR(13);

	-- WHERE
	SET @sql += 'WHERE 1=1';

	IF @startSequence IS NOT NULL
		SET @sql += ' AND pkID ' + CASE @order WHEN 0 THEN '<=' ELSE '>=' END + ' @startSequence'

	IF @from IS NOT NULL
		SET @sql += ' AND [ChangeDate] >= @from'

	IF @to IS NOT NULL
		SET @sql += ' AND [ChangeDate] <= @to'

	IF @type IS NOT NULL
		SET @sql += ' AND [Type] = @type'

	IF @action IS NOT NULL
		SET @sql += ' AND [Action] = @action'

	IF @changedBy IS NOT NULL
		SET @sql += ' AND [ChangedBy] = @changedBy'

	IF @deleted = 0
		SET @sql += ' AND [Deleted] = 0'

	-- ORDER BY
	SET @sql += CHAR(13) + 'ORDER BY pkID ' + CASE @order WHEN 0 THEN 'DESC' ELSE 'ASC' END

	SET @paramList = '@from 	        DATETIME,
					  @to				DATETIME,
					  @type 			NVARCHAR(255),
					  @action 			INT,
					  @changedBy		NVARCHAR(255),
					  @startSequence	BIGINT,
					  @maxRows			BIGINT,
					  @deleted			BIT'

	EXEC sp_executesql @sql, @paramList, @from, @to, @type, @action, @changedBy, @startSequence, @maxRows, @deleted

END

GO
PRINT N'Altering [dbo].[editDeleteChilds]...';

GO
ALTER PROCEDURE [dbo].[editDeleteChilds]
(
    @PageID			INT,
    @ForceDelete	INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON
    DECLARE @retval INT

	DECLARE @pages AS editDeletePageInternalTable
	
	INSERT INTO @pages (pkID) 
	SELECT TOP 5000
		fkChildID 
	FROM 
		tblTree 
	WHERE fkParentID=@PageID

	UPDATE @pages 
		SET PageGUID = tblPage.PageGUID
	FROM tblPage INNER JOIN @pages pages ON pages.pkID=tblPage.pkID

	DECLARE @sql NVARCHAR(200) = N'EXEC @retval=editDeletePageInternal @pages, @PageID=@PageID, @ForceDelete=@ForceDelete'
	DECLARE @params NVARCHAR(200) = N'@pages editDeletePageInternalTable READONLY, @PageID INT, @ForceDelete INT, @retval int OUTPUT'
	EXEC sp_executesql @sql, @params, @pages, @PageID, @ForceDelete, @retval=@retval OUTPUT

	DECLARE @deleteCount INT = (SELECT COUNT(*) FROM @pages)
	IF @deleteCount = 5000
	BEGIN
		SELECT finished = 0
	END ELSE BEGIN
		UPDATE tblContent SET IsLeafNode = 1 WHERE pkID=@PageID
		SELECT finished = 1
	END
        
	RETURN @retval
END
GO

PRINT N'Altering [dbo].[netContentLoadVersion]...';

GO
ALTER PROCEDURE dbo.netContentLoadVersion
(
	@ContentID	INT,
	@WorkID INT,
	@LangBranchID INT
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @CommonPropsWorkID INT
	DECLARE @IsMasterLanguage BIT
    DECLARE @ContentTypeID INT

	IF @WorkID IS NULL
	BEGIN
		IF @LangBranchID IS NULL OR NOT EXISTS(SELECT * FROM tblWorkContent WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID)
			SELECT @LangBranchID=COALESCE(fkMasterLanguageBranchID,1) FROM tblContent WHERE pkID=@ContentID

		SELECT @WorkID=[Version] FROM tblContentLanguage WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID AND Status = 4
		IF (@WorkID IS NULL OR @WorkID=0)
		BEGIN
			SELECT TOP 1 @WorkID=pkID FROM tblWorkContent WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID ORDER BY Saved, pkID DESC
		END
		
		IF (@WorkID IS NULL OR @WorkID=0)
		BEGIN
			EXEC netContentDataLoad @ContentID=@ContentID, @LanguageBranchID=@LangBranchID
			RETURN 0
		END		
	END
	
	/*Get the page type for the requested page*/
	SELECT @ContentTypeID = tblContent.fkContentTypeID FROM tblContent
		WHERE tblContent.pkID=@ContentID

	/* Get Language branch from page version*/
	SELECT @LangBranchID=fkLanguageBranchID FROM tblWorkContent WHERE pkID=@WorkID

	SELECT @IsMasterLanguage = CASE WHEN EXISTS(SELECT * FROM tblContent WHERE pkID=@ContentID AND fkMasterLanguageBranchID=@LangBranchID) THEN  1 ELSE 0 END
	IF (@IsMasterLanguage = 0)
	BEGIN
		SELECT @CommonPropsWorkID=tblContentLanguage.[Version] 
			FROM tblContentLanguage 
			INNER JOIN tblContent ON tblContent.pkID=tblContentLanguage.fkContentID
			WHERE tblContent.pkID=@ContentID AND tblContentLanguage.fkLanguageBranchID=tblContent.fkMasterLanguageBranchID
			
		/* Get data for page for non-master language*/
		SELECT
			tblContent.pkID AS PageLinkID,
			tblWorkContent.pkID AS PageLinkWorkID,
			fkParentID  AS PageParentLinkID,
			fkContentTypeID AS PageTypeID,
			NULL AS PageTypeName,
			CONVERT(INT,tblContent.VisibleInMenu) AS PageVisibleInMenu,
			tblContent.ChildOrderRule AS PageChildOrderRule,
			tblContent.PeerOrder AS PagePeerOrder,
			CONVERT(NVARCHAR(38),tblContent.ContentGUID) AS PageGUID,
			tblContent.ArchiveContentGUID AS PageArchiveLinkID,
			ContentAssetsID,
			ContentOwnerID,
			CONVERT(INT,Deleted) AS PageDeleted,
			DeletedBy AS PageDeletedBy,
			DeletedDate AS PageDeletedDate,
			(SELECT ChildOrderRule FROM tblContent AS ParentPage WHERE ParentPage.pkID=tblContent.fkParentID) AS PagePeerOrderRule,
			fkMasterLanguageBranchID AS PageMasterLanguageBranchID,
			CreatorName
		FROM
			tblWorkContent
		INNER JOIN
			tblContent
		ON
			tblContent.pkID = tblWorkContent.fkContentID
		WHERE
			tblContent.pkID = @ContentID
		AND
			tblWorkContent.pkID = @WorkID	
	END
	ELSE
	BEGIN
		/* Get data for page for master language*/
		SELECT
			tblContent.pkID AS PageLinkID,
			tblWorkContent.pkID AS PageLinkWorkID,
			fkParentID  AS PageParentLinkID,
			fkContentTypeID AS PageTypeID,
			NULL AS PageTypeName,
			CONVERT(INT,tblWorkContent.VisibleInMenu) AS PageVisibleInMenu,
			tblWorkContent.ChildOrderRule AS PageChildOrderRule,
			tblWorkContent.PeerOrder AS PagePeerOrder,
			CONVERT(NVARCHAR(38),tblContent.ContentGUID) AS PageGUID,
			tblWorkContent.ArchiveContentGUID AS PageArchiveLinkID,
			ContentAssetsID,
			ContentOwnerID,
			CONVERT(INT,Deleted) AS PageDeleted,
			DeletedBy AS PageDeletedBy,
			DeletedDate AS PageDeletedDate,
			(SELECT ChildOrderRule FROM tblContent AS ParentPage WHERE ParentPage.pkID=tblContent.fkParentID) AS PagePeerOrderRule,
			fkMasterLanguageBranchID AS PageMasterLanguageBranchID,
			tblContent.CreatorName
		FROM tblWorkContent
		INNER JOIN tblContent ON tblContent.pkID=tblWorkContent.fkContentID
		WHERE tblContent.pkID=@ContentID AND tblWorkContent.pkID=@WorkID
	END

	IF (@@ROWCOUNT = 0)
		RETURN 0
		
	/* Get data for page languages */
	SELECT
		W.Status as PageWorkStatus,
		W.fkContentID AS PageID,
		W.LinkType AS PageShortcutType,
		W.ExternalURL AS PageExternalURL,
		W.ContentLinkGUID AS PageShortcutLinkID,
		W.Name AS PageName,
		W.URLSegment AS PageURLSegment,
		W.LinkURL AS PageLinkURL,
		W.BlobUri,
		W.ThumbnailUri,
		W.Created AS PageCreated,
		tblContentLanguage.Changed AS PageChanged,
		W.Saved AS PageSaved,
		W.StartPublish AS PageStartPublish,
		W.StopPublish AS PageStopPublish,
		CASE WHEN tblContentLanguage.Status = 4 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS PagePendingPublish,
		tblContentLanguage.CreatorName AS PageCreatedBy,
		W.ChangedByName AS PageChangedBy,
		-- RTRIM(W.fkLanguageID) AS PageLanguageID,
		W.fkFrameID AS PageTargetFrame,
		W.ChangedOnPublish AS PageChangedOnPublish,
		CASE WHEN W.Status = 6 THEN 1 ELSE 0 END AS PageDelayedPublish,
		W.fkLanguageBranchID AS PageLanguageBranchID,
		W.DelayPublishUntil AS PageDelayPublishUntil
	FROM tblWorkContent AS W
	INNER JOIN tblContentLanguage ON tblContentLanguage.fkContentID=W.fkContentID
	WHERE tblContentLanguage.fkLanguageBranchID=W.fkLanguageBranchID
		AND W.pkID=@WorkID
	
	/* Get the property data */
	SELECT
		tblPageDefinition.Name AS PropertyName,
		tblPageDefinition.pkID as PropertyDefinitionID,
		ScopeName,
		CONVERT(INT, Boolean) AS Boolean,
		Number AS IntNumber,
		FloatNumber,
		PageType,
		PageLink AS ContentLink,
		LinkGuid,
		Date AS DateValue,
		String,
		LongString,
		tblWorkContent.fkLanguageBranchID AS LanguageBranchID
	FROM tblWorkProperty
	INNER JOIN tblWorkContent ON tblWorkContent.pkID=tblWorkProperty.fkWorkPageID
	INNER JOIN tblPageDefinition ON tblPageDefinition.pkID=tblWorkProperty.fkPageDefinitionID
	WHERE (tblWorkProperty.fkWorkPageID=@WorkID OR (tblWorkProperty.fkWorkPageID=@CommonPropsWorkID AND tblPageDefinition.LanguageSpecific<3 AND @IsMasterLanguage=0))
		   AND NOT tblPageDefinition.fkPageTypeID IS NULL

	/*Get built in category information*/
	SELECT
		fkContentID
	AS
		PageID,
		fkCategoryID,
		CategoryType,
		NULL
	FROM
		tblWorkCategory
	INNER JOIN
		tblWorkContent
	ON
		tblWorkContent.pkID = tblWorkCategory.fkWorkPageID
	WHERE
	(
		(@IsMasterLanguage = 0 AND fkWorkPageID = @CommonPropsWorkID)
		OR
		(@IsMasterLanguage = 1 AND fkWorkPageID = @WorkID)
	)
	AND
		CategoryType = 0
	ORDER BY
		fkCategoryID

	/* Get access information */
	SELECT
		fkContentID AS PageID,
		Name,
		IsRole,
		AccessMask
	FROM
		tblContentAccess
	WHERE 
	    fkContentID=@ContentID
	ORDER BY
	    IsRole DESC,
		Name

	/* Get all languages for the page */
	SELECT fkLanguageBranchID as PageLanguageBranchID FROM tblContentLanguage
		WHERE tblContentLanguage.fkContentID=@ContentID

	RETURN 0
END
GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7044
GO

PRINT N'Update complete.';
GO

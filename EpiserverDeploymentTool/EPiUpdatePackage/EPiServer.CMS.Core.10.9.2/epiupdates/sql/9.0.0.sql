--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7022)
				select 0, 'Already correct database version'
            else if (@ver = 7021)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery


GO
PRINT N'Dropping [dbo].[tblContent].[IDX_tblContent_ExternalFolderID]...';


GO
DROP INDEX [IDX_tblContent_ExternalFolderID]
    ON [dbo].[tblContent];


GO
PRINT N'Dropping [dbo].[DF_tblUnifiedPath_InheritAcl]...';


GO
ALTER TABLE [dbo].[tblUnifiedPath] DROP CONSTRAINT [DF_tblUnifiedPath_InheritAcl];


GO
PRINT N'Dropping [dbo].[DF_tblUnifiedPathAcl_IsRole]...';


GO
ALTER TABLE [dbo].[tblUnifiedPathAcl] DROP CONSTRAINT [DF_tblUnifiedPathAcl_IsRole];


GO
PRINT N'Dropping [dbo].[FK_tblRelation_tblItem_FromId]...';


GO
ALTER TABLE [dbo].[tblRelation] DROP CONSTRAINT [FK_tblRelation_tblItem_FromId];


GO
PRINT N'Dropping [dbo].[FK_tblRelation_tblItem_ToId]...';


GO
ALTER TABLE [dbo].[tblRelation] DROP CONSTRAINT [FK_tblRelation_tblItem_ToId];


GO
PRINT N'Dropping [dbo].[FK_tblUnifiedPathAcl_tblUnifiedPath]...';


GO
ALTER TABLE [dbo].[tblUnifiedPathAcl] DROP CONSTRAINT [FK_tblUnifiedPathAcl_tblUnifiedPath];


GO
PRINT N'Dropping [dbo].[FK_tblUnifiedPathProperty_tblUnifiedPath]...';


GO
ALTER TABLE [dbo].[tblUnifiedPathProperty] DROP CONSTRAINT [FK_tblUnifiedPathProperty_tblUnifiedPath];

GO
PRINT N'Dropping [dbo].[tblIndexBigInt]...';


GO
DROP TABLE [dbo].[tblIndexBigInt];

GO
PRINT N'Dropping [dbo].[ItemDelete]...';


GO
DROP PROCEDURE [dbo].[ItemDelete];


GO
PRINT N'Dropping [dbo].[ItemFindByName]...';


GO
DROP PROCEDURE [dbo].[ItemFindByName];


GO
PRINT N'Dropping [dbo].[ItemList]...';


GO
DROP PROCEDURE [dbo].[ItemList];


GO
PRINT N'Dropping [dbo].[ItemLoad]...';


GO
DROP PROCEDURE [dbo].[ItemLoad];


GO
PRINT N'Dropping [dbo].[ItemSave]...';


GO
DROP PROCEDURE [dbo].[ItemSave];


GO
PRINT N'Dropping [dbo].[netPageListExternalFolderID]...';


GO
DROP PROCEDURE [dbo].[netPageListExternalFolderID];


GO
PRINT N'Dropping [dbo].[netPageMaxFolderId]...';


GO
DROP PROCEDURE [dbo].[netPageMaxFolderId];


GO
PRINT N'Dropping [dbo].[netQuickSearchByFolderID]...';


GO
DROP PROCEDURE [dbo].[netQuickSearchByFolderID];


GO
PRINT N'Dropping [dbo].[netQuickSearchListFolderID]...';


GO
DROP PROCEDURE [dbo].[netQuickSearchListFolderID];


GO
PRINT N'Dropping [dbo].[netUnifiedPathDelete]...';


GO
DROP PROCEDURE [dbo].[netUnifiedPathDelete];


GO
PRINT N'Dropping [dbo].[netUnifiedPathDeleteAclAndMeta]...';


GO
DROP PROCEDURE [dbo].[netUnifiedPathDeleteAclAndMeta];


GO
PRINT N'Dropping [dbo].[netUnifiedPathDeleteAll]...';


GO
DROP PROCEDURE [dbo].[netUnifiedPathDeleteAll];


GO
PRINT N'Dropping [dbo].[netUnifiedPathDeleteMembership]...';


GO
DROP PROCEDURE [dbo].[netUnifiedPathDeleteMembership];


GO
PRINT N'Dropping [dbo].[netUnifiedPathLoad]...';


GO
DROP PROCEDURE [dbo].[netUnifiedPathLoad];


GO
PRINT N'Dropping [dbo].[netUnifiedPathMove]...';


GO
DROP PROCEDURE [dbo].[netUnifiedPathMove];


GO
PRINT N'Dropping [dbo].[netUnifiedPathSave]...';


GO
DROP PROCEDURE [dbo].[netUnifiedPathSave];


GO
PRINT N'Dropping [dbo].[netUnifiedPathSaveAclEntry]...';


GO
DROP PROCEDURE [dbo].[netUnifiedPathSaveAclEntry];


GO
PRINT N'Dropping [dbo].[netUnifiedPathSavePropEntry]...';


GO
DROP PROCEDURE [dbo].[netUnifiedPathSavePropEntry];


GO
PRINT N'Dropping [dbo].[netUnifiedPathSearch]...';


GO
DROP PROCEDURE [dbo].[netUnifiedPathSearch];


GO
PRINT N'Dropping [dbo].[RelationAdd]...';


GO
DROP PROCEDURE [dbo].[RelationAdd];


GO
PRINT N'Dropping [dbo].[RelationListFrom]...';


GO
DROP PROCEDURE [dbo].[RelationListFrom];


GO
PRINT N'Dropping [dbo].[RelationListTo]...';


GO
DROP PROCEDURE [dbo].[RelationListTo];


GO
PRINT N'Dropping [dbo].[RelationRemove]...';


GO
DROP PROCEDURE [dbo].[RelationRemove];


GO
PRINT N'Dropping [dbo].[SchemaDelete]...';


GO
DROP PROCEDURE [dbo].[SchemaDelete];


GO
PRINT N'Dropping [dbo].[SchemaItemSave]...';


GO
DROP PROCEDURE [dbo].[SchemaItemSave];


GO
PRINT N'Dropping [dbo].[SchemaList]...';


GO
DROP PROCEDURE [dbo].[SchemaList];


GO
PRINT N'Dropping [dbo].[SchemaLoad]...';


GO
DROP PROCEDURE [dbo].[SchemaLoad];


GO
PRINT N'Dropping [dbo].[SchemaSave]...';


GO
DROP PROCEDURE [dbo].[SchemaSave];


GO
PRINT N'Dropping [dbo].[TestClearItems]...';


GO
DROP PROCEDURE [dbo].[TestClearItems];


GO
PRINT N'Dropping [dbo].[tblIndexDateTime]...';


GO
DROP TABLE [dbo].[tblIndexDateTime];


GO
PRINT N'Dropping [dbo].[tblIndexDecimal]...';


GO
DROP TABLE [dbo].[tblIndexDecimal];


GO
PRINT N'Dropping [dbo].[tblIndexFloat]...';


GO
DROP TABLE [dbo].[tblIndexFloat];


GO
PRINT N'Dropping [dbo].[tblIndexGuid]...';


GO
DROP TABLE [dbo].[tblIndexGuid];


GO
PRINT N'Dropping [dbo].[tblIndexInt]...';


GO
DROP TABLE [dbo].[tblIndexInt];


GO
PRINT N'Dropping [dbo].[tblIndexString]...';


GO
DROP TABLE [dbo].[tblIndexString];


GO
PRINT N'Dropping [dbo].[tblItem]...';


GO
DROP TABLE [dbo].[tblItem];


GO
PRINT N'Dropping [dbo].[tblRelation]...';


GO
DROP TABLE [dbo].[tblRelation];


GO
PRINT N'Dropping [dbo].[tblSchemaItem]...';


GO
DROP TABLE [dbo].[tblSchemaItem];


GO

PRINT N'Dropping [dbo].[tblSchema]...';


GO
DROP TABLE [dbo].[tblSchema];


GO

PRINT N'Dropping [dbo].[tblAccessType]...';


GO
DROP TABLE [dbo].[tblAccessType];


GO

PRINT N'Dropping [dbo].[tblUnifiedPath]...';


GO
DROP TABLE [dbo].[tblUnifiedPath];


GO
PRINT N'Dropping [dbo].[tblUnifiedPathAcl]...';


GO
DROP TABLE [dbo].[tblUnifiedPathAcl];


GO
PRINT N'Dropping [dbo].[tblUnifiedPathProperty]...';


GO
DROP TABLE [dbo].[tblUnifiedPathProperty];


GO
PRINT N'Altering [dbo].[tblContent]...';


GO
ALTER TABLE [dbo].[tblContent] DROP COLUMN [ExternalFolderID];


GO
PRINT N'Altering [dbo].[tblPage]...';


GO
ALTER VIEW [dbo].[tblPage]
AS
SELECT  [pkID],
		[fkContentTypeID] AS fkPageTypeID,
		[fkParentID],
		[ArchiveContentGUID] AS ArchivePageGUID,
		[CreatorName],
		[ContentGUID] AS PageGUID,
		[VisibleInMenu],
		[Deleted],
		CAST (0 AS BIT) AS PendingPublish,
		[ChildOrderRule],
		[PeerOrder],
		[ContentAssetsID],
		[ContentOwnerID],
		NULL as PublishedVersion,
		[fkMasterLanguageBranchID],
		[ContentPath] AS PagePath,
		[ContentType],
		[DeletedBy],
		[DeletedDate]
FROM    dbo.tblContent
GO
PRINT N'Altering [dbo].[editSaveContentVersionData]...';


GO
ALTER PROCEDURE [dbo].[editSaveContentVersionData]
(
	@WorkContentID		INT,
	@UserName			NVARCHAR(255),
	@Saved				DATETIME,
	@Name				NVARCHAR(255)		= NULL,
	@ExternalURL		NVARCHAR(255)		= NULL,
	@Created			DATETIME			= NULL,
	@Changed			BIT					= 0,
	@StartPublish		DATETIME			= NULL,
	@StopPublish		DATETIME			= NULL,
	@ChildOrder			INT					= 3,
	@PeerOrder			INT					= 100,
	@ContentLinkGUID	UNIQUEIDENTIFIER	= NULL,
	@LinkURL			NVARCHAR(255)		= NULL,
	@BlobUri			NVARCHAR(255)		= NULL,
	@ThumbnailUri		NVARCHAR(255)		= NULL,
	@LinkType			INT					= 0,
	@FrameID			INT					= NULL,
	@VisibleInMenu		BIT					= NULL,
	@ArchiveContentGUID	UNIQUEIDENTIFIER	= NULL,
	@ContentAssetsID	UNIQUEIDENTIFIER	= NULL,
	@ContentOwnerID		UNIQUEIDENTIFIER	= NULL,
	@URLSegment			NVARCHAR(255)		= NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @ChangedDate			DATETIME
	DECLARE @ContentID				INT
	DECLARE @ContentTypeID			INT
	DECLARE @ParentID				INT
	DECLARE @AssetsID				UNIQUEIDENTIFIER
	DECLARE @OwnerID				UNIQUEIDENTIFIER
	DECLARE @CurrentLangBranchID	INT
	DECLARE @IsMasterLang			BIT
	
	/* Pull some useful information from the published Content */
	SELECT
		@ContentID				= fkContentID,
		@ParentID				= fkParentID,
		@ContentTypeID			= fkContentTypeID,
		@AssetsID				= ContentAssetsID,
		@OwnerID				= ContentOwnerID,
		@IsMasterLang			= CASE WHEN tblContent.fkMasterLanguageBranchID=tblWorkContent.fkLanguageBranchID THEN 1 ELSE 0 END,
		@CurrentLangBranchID	= fkLanguageBranchID
	FROM
		tblWorkContent
	INNER JOIN tblContent ON tblContent.pkID=tblWorkContent.fkContentID
	INNER JOIN tblContentType ON tblContentType.pkID=tblContent.fkContentTypeID
	WHERE
		tblWorkContent.pkID=@WorkContentID
	
	if (@ContentID IS NULL)
	BEGIN
		RAISERROR (N'editSaveContentVersionData: The WorkContentId dosen´t exist (WorkContentID=%d)', 16, 1, @WorkContentID)
		RETURN -1
	END			
		IF ((@AssetsID IS NULL) AND (@ContentAssetsID IS NOT NULL))
		BEGIN
			UPDATE
				tblContent
			SET
				ContentAssetsID = @ContentAssetsID
			WHERE
				pkID=@ContentID
		END

		IF ((@OwnerID IS NULL) AND (@ContentOwnerID IS NOT NULL))
		BEGIN
			UPDATE
				tblContent
			SET
				ContentOwnerID = @ContentOwnerID
			WHERE
				pkID=@ContentID
		END

		/* Set new values for work Content */
		UPDATE
			tblWorkContent
		SET
			ChangedByName		= @UserName,
			ContentLinkGUID		= @ContentLinkGUID,
			ArchiveContentGUID	= @ArchiveContentGUID,
			fkFrameID			= @FrameID,
			Name				= @Name,
			LinkURL				= @LinkURL,
			BlobUri				= @BlobUri,
			ThumbnailUri		= @ThumbnailUri,
			ExternalURL			= @ExternalURL,
			URLSegment			= @URLSegment,
			VisibleInMenu		= @VisibleInMenu,
			LinkType			= @LinkType,
			Created				= COALESCE(@Created, Created),
			Saved				= @Saved,
			StartPublish		= COALESCE(@StartPublish, StartPublish),
			StopPublish			= @StopPublish,
			ChildOrderRule		= @ChildOrder,
			PeerOrder			= COALESCE(@PeerOrder, PeerOrder),
			ChangedOnPublish	= @Changed
		WHERE
			pkID=@WorkContentID
		
		IF EXISTS(SELECT * FROM tblContentLanguage WHERE fkContentID=@ContentID AND fkLanguageBranchID=@CurrentLangBranchID AND Status <> 4)
		BEGIN

			UPDATE
				tblContentLanguage
			SET
				Name			= @Name,
				Created			= @Created,
				Saved			= @Saved,
				URLSegment		= @URLSegment,
				LinkURL			= @LinkURL,
				BlobUri			= @BlobUri,
				ThumbnailUri	= @ThumbnailUri,
				StartPublish	= COALESCE(@StartPublish, StartPublish),
				StopPublish		= @StopPublish,
				ExternalURL		= Lower(@ExternalURL),
				fkFrameID		= @FrameID,
				AutomaticLink	= CASE WHEN @LinkType = 2 OR @LinkType = 3 THEN 0 ELSE 1 END,
				FetchData		= CASE WHEN @LinkType = 4 THEN 1 ELSE 0 END
			WHERE
				fkContentID=@ContentID AND fkLanguageBranchID=@CurrentLangBranchID

			/* Set some values needed for proper display in edit tree even though we have not yet published the Content */
			IF @IsMasterLang = 1
			BEGIN
				UPDATE
					tblContent
				SET
					ArchiveContentGUID	= @ArchiveContentGUID,
					ChildOrderRule		= @ChildOrder,
					PeerOrder			= @PeerOrder,
					VisibleInMenu		= @VisibleInMenu
				WHERE
					pkID=@ContentID 
			END

		END
END
GO
PRINT N'Altering [dbo].[netContentCreate]...';


GO
ALTER PROCEDURE [dbo].[netContentCreate]
(
	@UserName NVARCHAR(255),
	@ParentID			INT,
	@ContentTypeID		INT,
	@ContentGUID		UNIQUEIDENTIFIER,
	@ContentType		INT,
	@WastebasketID		INT, 
	@ContentAssetsID	UNIQUEIDENTIFIER = NULL,
	@ContentOwnerID		UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @ContentID INT
	DECLARE @Delete		BIT
	
	/* Create materialized path to content */
	DECLARE @Path VARCHAR(7000)
	DECLARE @IsParentLeafNode BIT
	SELECT @Path = ContentPath + CONVERT(VARCHAR, @ParentID) + '.', @IsParentLeafNode = IsLeafNode FROM tblContent WHERE pkID=@ParentID
	IF @IsParentLeafNode = 1
		UPDATE tblContent SET IsLeafNode = 0 WHERE pkID=@ParentID

    
    SET @Delete = 0
    IF(@WastebasketID = @ParentID)
		SET @Delete=1
    ELSE IF (EXISTS (SELECT NestingLevel FROM tblTree WHERE fkParentID=@WastebasketID AND fkChildID=@ParentID))
        SET @Delete=1
    
	/* Create new content */
	INSERT INTO tblContent 
		(fkContentTypeID, CreatorName, fkParentID, ContentAssetsID, ContentOwnerID, ContentGUID, ContentPath, ContentType, Deleted)
	VALUES
		(@ContentTypeID, @UserName, @ParentID, @ContentAssetsID, @ContentOwnerID, @ContentGUID, @Path, @ContentType, @Delete)

	/* Remember pkID of content */
	SET @ContentID= SCOPE_IDENTITY() 
	 
	/* Update content tree with info about this content */
	INSERT INTO tblTree
		(fkParentID, fkChildID, NestingLevel)
	SELECT 
		fkParentID,
		@ContentID,
		NestingLevel+1
	FROM tblTree
	WHERE fkChildID=@ParentID
	UNION ALL
	SELECT
		@ParentID,
		@ContentID,
		1
	  

	RETURN @ContentID
END
GO
PRINT N'Altering [dbo].[netContentDataLoad]...';


GO
ALTER PROCEDURE [dbo].[netContentDataLoad]
(
	@ContentID	INT, 
	@LanguageBranchID INT
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ContentTypeID INT
	DECLARE @MasterLanguageID INT

	SELECT @ContentTypeID = tblContent.fkContentTypeID FROM tblContent
		WHERE tblContent.pkID=@ContentID

	/*This procedure should always return a page (if exist), preferable in requested language else in master language*/
	IF (@LanguageBranchID = -1 OR NOT EXISTS (SELECT Name FROM tblContentLanguage WHERE fkContentID=@ContentID AND fkLanguageBranchID = @LanguageBranchID))
		SELECT @LanguageBranchID = fkMasterLanguageBranchID  FROM tblContent
			WHERE tblContent.pkID=@ContentID

	SELECT @MasterLanguageID = fkMasterLanguageBranchID FROM tblContent WHERE tblContent.pkID=@ContentID

	/* Get data for page */
	SELECT
		tblContent.pkID AS PageLinkID,
		NULL AS PageLinkWorkID,
		fkParentID  AS PageParentLinkID,
		fkContentTypeID AS PageTypeID,
		NULL AS PageTypeName,
		CONVERT(INT,VisibleInMenu) AS PageVisibleInMenu,
		ChildOrderRule AS PageChildOrderRule,
		PeerOrder AS PagePeerOrder,
		CONVERT(NVARCHAR(38),tblContent.ContentGUID) AS PageGUID,
		ArchiveContentGUID AS PageArchiveLinkID,
		ContentAssetsID,
		ContentOwnerID,
		CONVERT(INT,Deleted) AS PageDeleted,
		DeletedBy AS PageDeletedBy,
		DeletedDate AS PageDeletedDate,
		(SELECT ChildOrderRule FROM tblContent AS ParentPage WHERE ParentPage.pkID=tblContent.fkParentID) AS PagePeerOrderRule,
		fkMasterLanguageBranchID AS PageMasterLanguageBranchID,
		CreatorName
	FROM tblContent
	WHERE tblContent.pkID=@ContentID

	IF (@@ROWCOUNT = 0)
		RETURN 0
		
	/* Get data for page languages */
	SELECT
		L.fkContentID AS PageID,
		CASE L.AutomaticLink
			WHEN 1 THEN
				(CASE
					WHEN L.ContentLinkGUID IS NULL THEN 0	/* EPnLinkNormal */
					WHEN L.FetchData=1 THEN 4				/* EPnLinkFetchdata */
					ELSE 1								/* EPnLinkShortcut */
				END)
			ELSE
				(CASE
					WHEN L.LinkURL=N'#' THEN 3				/* EPnLinkInactive */
					ELSE 2								/* EPnLinkExternal */
				END)
		END AS PageShortcutType,
		L.ExternalURL AS PageExternalURL,
		L.ContentLinkGUID AS PageShortcutLinkID,
		L.Name AS PageName,
		L.URLSegment AS PageURLSegment,
		L.LinkURL AS PageLinkURL,
		L.BlobUri,
		L.ThumbnailUri,
		L.Created AS PageCreated,
		L.Changed AS PageChanged,
		L.Saved AS PageSaved,
		L.StartPublish AS PageStartPublish,
		L.StopPublish AS PageStopPublish,
		CASE WHEN L.Status = 4 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS PagePendingPublish,
		L.CreatorName AS PageCreatedBy,
		L.ChangedByName AS PageChangedBy,
		-- RTRIM(tblContentLanguage.fkLanguageID) AS PageLanguageID,
		L.fkFrameID AS PageTargetFrame,
		0 AS PageChangedOnPublish,
		0 AS PageDelayedPublish,
		L.fkLanguageBranchID AS PageLanguageBranchID,
		L.Status as PageWorkStatus,
		L.DelayPublishUntil AS PageDelayPublishUntil
	FROM tblContentLanguage AS L
	WHERE L.fkContentID=@ContentID
		AND L.fkLanguageBranchID=@LanguageBranchID
	
	/* Get the property data for the requested language */
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
		tblProperty.fkLanguageBranchID AS LanguageBranchID
	FROM tblProperty
	INNER JOIN tblPageDefinition ON tblPageDefinition.pkID = tblProperty.fkPageDefinitionID
	WHERE tblProperty.fkPageID=@ContentID AND NOT tblPageDefinition.fkPageTypeID IS NULL
		AND (tblProperty.fkLanguageBranchID = @LanguageBranchID 
		OR (tblProperty.fkLanguageBranchID = @MasterLanguageID AND tblPageDefinition.LanguageSpecific < 3))

	/*Get category information*/
	SELECT fkPageID AS PageID,fkCategoryID,CategoryType
	FROM tblCategoryPage
	WHERE fkPageID=@ContentID AND CategoryType=0
	ORDER BY fkCategoryID

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
PRINT N'Altering [dbo].[netContentListPaged]...';


GO
ALTER PROCEDURE dbo.netContentListPaged
(
	@Binary VARBINARY(8000),
	@Threshold INT = 0,
	@LanguageBranchID INT
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ContentItems TABLE (LocalPageID INT, LocalLanguageID INT)
	DECLARE	@Length SMALLINT
	DECLARE @Index SMALLINT
	SET @Index = 1
	SET @Length = DATALENGTH(@Binary)
	WHILE (@Index <= @Length)
	BEGIN
		INSERT INTO @ContentItems(LocalPageID) VALUES(SUBSTRING(@Binary, @Index, 4))
		SET @Index = @Index + 4
	END

	/* We need to know which languages exist */
	UPDATE @ContentItems SET 
		LocalLanguageID = CASE WHEN fkLanguageBranchID IS NULL THEN fkMasterLanguageBranchID ELSE fkLanguageBranchID END
	FROM @ContentItems AS P
	INNER JOIN tblContent ON tblContent.pkID = P.LocalPageID
	LEFT JOIN tblContentLanguage ON P.LocalPageID = tblContentLanguage.fkContentID AND tblContentLanguage.fkLanguageBranchID = @LanguageBranchID

	/* Get all languages for all items*/
	SELECT tblContentLanguage.fkContentID as PageLinkID, tblContent.fkContentTypeID as PageTypeID, tblContentLanguage.fkLanguageBranchID as PageLanguageBranchID 
	FROM tblContentLanguage
	INNER JOIN @ContentItems on LocalPageID=tblContentLanguage.fkContentID
	INNER JOIN tblContent ON tblContent.pkID = tblContentLanguage.fkContentID
	ORDER BY tblContentLanguage.fkContentID

	/* Get all language versions that is requested (including master) */
	SELECT
		L.Status AS PageWorkStatus,
		L.fkContentID AS PageLinkID,
		NULL AS PageLinkWorkID,
		CASE AutomaticLink
			WHEN 1 THEN
				(CASE
					WHEN L.ContentLinkGUID IS NULL THEN 0	/* EPnLinkNormal */
					WHEN L.FetchData=1 THEN 4				/* EPnLinkFetchdata */
					ELSE 1								/* EPnLinkShortcut */
				END)
			ELSE
				(CASE
					WHEN L.LinkURL=N'#' THEN 3				/* EPnLinkInactive */
					ELSE 2								/* EPnLinkExternal */
				END)
		END AS PageShortcutType,
		L.ExternalURL AS PageExternalURL,
		L.ContentLinkGUID AS PageShortcutLinkID,
		L.Name AS PageName,
		L.URLSegment AS PageURLSegment,
		L.LinkURL AS PageLinkURL,
		L.BlobUri,
		L.ThumbnailUri,
		L.Created AS PageCreated,
		L.Changed AS PageChanged,
		L.Saved AS PageSaved,
		L.StartPublish AS PageStartPublish,
		L.StopPublish AS PageStopPublish,
		CASE WHEN L.Status = 4 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS PagePendingPublish,
		L.CreatorName AS PageCreatedBy,
		L.ChangedByName AS PageChangedBy,
		L.fkFrameID AS PageTargetFrame,
		0 AS PageChangedOnPublish,
		0 AS PageDelayedPublish,
		L.fkLanguageBranchID AS PageLanguageBranchID,
		L.DelayPublishUntil AS PageDelayPublishUntil
	FROM @ContentItems AS P
	INNER JOIN tblContentLanguage AS L ON LocalPageID=L.fkContentID
	WHERE L.fkLanguageBranchID = P.LocalLanguageID
	ORDER BY L.fkContentID

	IF (@@ROWCOUNT = 0)
	BEGIN
		RETURN
	END
		

/* Get data for page */
	SELECT
		LocalPageID AS PageLinkID,
		NULL AS PageLinkWorkID,
		fkParentID  AS PageParentLinkID,
		fkContentTypeID AS PageTypeID,
		NULL AS PageTypeName,
		CONVERT(INT,VisibleInMenu) AS PageVisibleInMenu,
		ChildOrderRule AS PageChildOrderRule,
		0 AS PagePeerOrderRule,	-- No longer used
		PeerOrder AS PagePeerOrder,
		CONVERT(NVARCHAR(38),tblContent.ContentGUID) AS PageGUID,
		ArchiveContentGUID AS PageArchiveLinkID,
		ContentAssetsID,
		ContentOwnerID,
		CONVERT(INT,Deleted) AS PageDeleted,
		DeletedBy AS PageDeletedBy,
		DeletedDate AS PageDeletedDate,
		fkMasterLanguageBranchID AS PageMasterLanguageBranchID,
		CreatorName
	FROM @ContentItems
	INNER JOIN tblContent ON LocalPageID=tblContent.pkID
	ORDER BY tblContent.pkID

	IF (@@ROWCOUNT = 0)
	BEGIN
		RETURN
	END

	
	/* Get the properties */
	/* NOTE! The CASE:s for LongString and Guid uses the precomputed LongStringLength to avoid 
	referencing LongString which may slow down the query */
	SELECT
		tblContentProperty.fkContentID AS PageLinkID,
		NULL AS PageLinkWorkID,
		tblPropertyDefinition.Name AS PropertyName,
		tblPropertyDefinition.pkID as PropertyDefinitionID,
		ScopeName,
		CONVERT(INT, Boolean) AS Boolean,
		Number AS IntNumber,
		FloatNumber,
		tblContentProperty.ContentType AS PageType,
		ContentLink,
		LinkGuid,	
		Date AS DateValue,
		String,
		(CASE 
			WHEN (@Threshold = 0) OR (COALESCE(LongStringLength, 2147483647) < @Threshold) THEN
				LongString
			ELSE
				NULL
		END) AS LongString,
		tblContentProperty.fkLanguageBranchID AS PageLanguageBranchID,
		(CASE 
			WHEN (@Threshold = 0) OR (COALESCE(LongStringLength, 2147483647) < @Threshold) THEN
				NULL
			ELSE
				guid
		END) AS Guid
	FROM @ContentItems AS P
	INNER JOIN tblContent ON tblContent.pkID=P.LocalPageID
	INNER JOIN tblContentProperty WITH (NOLOCK) ON tblContent.pkID=tblContentProperty.fkContentID --The join with tblContent ensures data integrity
	INNER JOIN tblPropertyDefinition ON tblPropertyDefinition.pkID=tblContentProperty.fkPropertyDefinitionID
	WHERE NOT tblPropertyDefinition.fkContentTypeID IS NULL AND
		(tblContentProperty.fkLanguageBranchID = P.LocalLanguageID
	OR
		tblPropertyDefinition.LanguageSpecific<3)
	ORDER BY tblContent.pkID

	/*Get category information*/
	SELECT 
		fkContentID AS PageLinkID,
		NULL AS PageLinkWorkID,
		fkCategoryID,
		CategoryType
	FROM tblContentCategory
	INNER JOIN @ContentItems ON LocalPageID=tblContentCategory.fkContentID
	WHERE CategoryType=0
	ORDER BY fkContentID,fkCategoryID

	/* Get access information */
	SELECT
		fkContentID AS PageLinkID,
		NULL AS PageLinkWorkID,
		tblContentAccess.Name,
		IsRole,
		AccessMask
	FROM
		@ContentItems
	INNER JOIN 
	    tblContentAccess ON LocalPageID=tblContentAccess.fkContentID
	ORDER BY
		fkContentID
END
GO
PRINT N'Altering [dbo].[netContentListVersionsPaged]...';


GO
ALTER PROCEDURE dbo.netContentListVersionsPaged
(
	@Binary VARBINARY(8000),
	@Threshold INT = 0
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ContentVersions TABLE (VersionID INT, ContentID INT, MasterVersionID INT, LanguageBranchID INT, ContentTypeID INT)
	DECLARE @WorkId INT;
	DECLARE	@Length SMALLINT
	DECLARE @Index SMALLINT
	SET @Index = 1
	SET @Length = DATALENGTH(@Binary)
	WHILE (@Index <= @Length)
	BEGIN
		SET @WorkId = SUBSTRING(@Binary, @Index, 4)

		INSERT INTO @ContentVersions VALUES(@WorkId, NULL, NULL, NULL, NULL)
		SET @Index = @Index + 4
	END

	/* Add some meta data to temp table*/
	UPDATE @ContentVersions SET ContentID = tblContent.pkID, MasterVersionID = tblContentLanguage.Version, LanguageBranchID = tblWorkContent.fkLanguageBranchID, ContentTypeID = tblContent.fkContentTypeID
	FROM tblWorkContent INNER JOIN tblContent on tblWorkContent.fkContentID = tblContent.pkID
	INNER JOIN tblContentLanguage ON tblContentLanguage.fkContentID = tblContent.pkID
	WHERE tblWorkContent.pkID = VersionID AND tblWorkContent.fkLanguageBranchID = tblContentLanguage.fkLanguageBranchID

	/*Add master language version to support loading non localized props*/
	INSERT INTO @ContentVersions (ContentID, MasterVersionID, LanguageBranchID, ContentTypeID)
	SELECT DISTINCT tblContent.pkID, tblContentLanguage.Version, tblContentLanguage.fkLanguageBranchID, tblContent.fkContentTypeID 
	FROM @ContentVersions AS CV INNER JOIN tblContent ON CV.ContentID = tblContent.pkID
	INNER JOIN tblContentLanguage ON tblContent.pkID = tblContentLanguage.fkContentID
	WHERE tblContent.fkMasterLanguageBranchID = tblContentLanguage.fkLanguageBranchID

	/* Get all languages for all items*/
	SELECT DISTINCT ContentID AS PageLinkID, ContentTypeID as PageTypeID, tblContentLanguage.fkLanguageBranchID as PageLanguageBranchID 
	FROM @ContentVersions AS CV INNER JOIN tblContentLanguage ON CV.ContentID = tblContentLanguage.fkContentID
	WHERE CV.VersionID IS NOT NULL
	ORDER BY ContentID

	/* Get data for languages */
	SELECT
		W.Status AS PageWorkStatus,
		W.fkContentID AS PageLinkID,
		W.pkID AS PageLinkWorkID,
		W.LinkType AS PageShortcutType,
		W.ExternalURL AS PageExternalURL,
		W.ContentLinkGUID AS PageShortcutLinkID,
		W.Name AS PageName,
		W.URLSegment AS PageURLSegment,
		W.LinkURL AS PageLinkURL,
		W.BlobUri,
		W.ThumbnailUri,
		W.Created AS PageCreated,
		L.Changed AS PageChanged,
		W.Saved AS PageSaved,
		W.StartPublish AS PageStartPublish,
		W.StopPublish AS PageStopPublish,
		CASE WHEN L.Status = 4 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS PagePendingPublish,
		L.CreatorName AS PageCreatedBy,
		W.ChangedByName AS PageChangedBy,
		W.fkFrameID AS PageTargetFrame,
		W.ChangedOnPublish AS PageChangedOnPublish,
		CASE WHEN W.Status = 6 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS  PageDelayedPublish,
		W.fkLanguageBranchID AS PageLanguageBranchID,
		W.DelayPublishUntil AS PageDelayPublishUntil
	FROM @ContentVersions AS CV
	INNER JOIN tblWorkContent AS W ON CV.VersionID = W.pkID 
	INNER JOIN tblContentLanguage AS L ON CV.ContentID = L.fkContentID
	WHERE 
		L.fkLanguageBranchID = W.fkLanguageBranchID

	ORDER BY L.fkContentID

	IF (@@ROWCOUNT = 0)
	BEGIN
		RETURN
	END

	/* Get common data for all versions of a content */
	SELECT
		CV.ContentID AS PageLinkID,
		CV.VersionID AS PageLinkWorkID,
		fkParentID  AS PageParentLinkID,
		fkContentTypeID AS PageTypeID,
		NULL AS PageTypeName,
		CONVERT(INT,VisibleInMenu) AS PageVisibleInMenu,
		ChildOrderRule AS PageChildOrderRule,
		0 AS PagePeerOrderRule,	-- No longer used
		PeerOrder AS PagePeerOrder,
		CONVERT(NVARCHAR(38),tblContent.ContentGUID) AS PageGUID,
		ArchiveContentGUID AS PageArchiveLinkID,
		ContentAssetsID,
		ContentOwnerID,
		CONVERT(INT,Deleted) AS PageDeleted,
		DeletedBy AS PageDeletedBy,
		DeletedDate AS PageDeletedDate,
		fkMasterLanguageBranchID AS PageMasterLanguageBranchID,
		CreatorName
	FROM @ContentVersions AS CV
	INNER JOIN tblContent ON CV.ContentID = tblContent.pkID
	WHERE CV.VersionID IS NOT NULL
	ORDER BY CV.ContentID

	IF (@@ROWCOUNT = 0)
	BEGIN
		RETURN
	END
		
	
	/* Get the properties for the specific versions*/
	SELECT
		CV.ContentID AS PageLinkID,
		CV.VersionID AS PageLinkWorkID,
		tblPropertyDefinition.Name AS PropertyName,
		tblPropertyDefinition.pkID as PropertyDefinitionID,
		ScopeName,
		CONVERT(INT, Boolean) AS Boolean,
		Number AS IntNumber,
		FloatNumber,
		P.ContentType AS PageType,
		ContentLink,
		LinkGuid,	
		Date AS DateValue,
		String,
		LongString,
		CV.LanguageBranchID AS PageLanguageBranchID
	FROM tblWorkContentProperty AS P 
	INNER JOIN @ContentVersions AS CV ON P.fkWorkContentID = CV.VersionID 
	INNER JOIN tblPropertyDefinition ON tblPropertyDefinition.pkID = P.fkPropertyDefinitionID
	WHERE NOT tblPropertyDefinition.fkContentTypeID IS NULL
	ORDER BY CV.ContentID

	/* Get the non language specific properties from master language*/
	SELECT
		CV.ContentID AS PageLinkID,
		CV.VersionID AS PageLinkWorkID,
		tblPropertyDefinition.Name AS PropertyName,
		tblPropertyDefinition.pkID as PropertyDefinitionID,
		ScopeName,
		CONVERT(INT, Boolean) AS Boolean,
		Number AS IntNumber,
		FloatNumber,
		P.ContentType AS PageType,
		ContentLink,
		LinkGuid,	
		Date AS DateValue,
		String,
		LongString,
		CV.LanguageBranchID AS PageLanguageBranchID
	FROM tblWorkContentProperty AS P
	INNER JOIN tblWorkContent AS W ON P.fkWorkContentID = W.pkID
	INNER JOIN @ContentVersions AS CV ON W.fkContentID = CV.ContentID
	INNER JOIN tblPropertyDefinition ON tblPropertyDefinition.pkID = P.fkPropertyDefinitionID
	WHERE NOT tblPropertyDefinition.fkContentTypeID IS NULL AND
		P.fkWorkContentID = CV.MasterVersionID AND tblPropertyDefinition.LanguageSpecific<3
	ORDER BY CV.ContentID

	/*Get category information*/
	SELECT DISTINCT
		CV.ContentID AS PageLinkID,
		CV.VersionID AS PageLinkWorkID,
		fkCategoryID,
		CategoryType
	FROM tblWorkContentCategory
	INNER JOIN tblWorkContent ON tblWorkContentCategory.fkWorkContentID = tblWorkContent.pkID
	INNER JOIN @ContentVersions AS CV ON CV.ContentID = tblWorkContent.fkContentID 
	INNER JOIN @ContentVersions AS MasterVersion ON CV.ContentID = MasterVersion.ContentID
	WHERE CategoryType=0 AND (CV.VersionID = tblWorkContent.pkID OR
	(MasterVersion.VersionID IS NULL AND tblWorkContentCategory.fkWorkContentID = MasterVersion.MasterVersionID 
		AND MasterVersion.LanguageBranchID <> CV.LanguageBranchID))
	ORDER BY CV.ContentID,fkCategoryID

	/* Get access information */
	SELECT
		CV.ContentID AS PageLinkID,
		CV.VersionID AS PageLinkWorkID,
		tblContentAccess.Name,
		IsRole,
		AccessMask
	FROM
		@ContentVersions as CV
	INNER JOIN 
	    tblContentAccess ON ContentID=tblContentAccess.fkContentID
	ORDER BY
		fkContentID
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
			SELECT TOP 1 @WorkID=pkID FROM tblWorkContent WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID ORDER BY Saved DESC
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
PRINT N'Altering [dbo].[netFindContentCoreDataByContentGuid]...';


GO
ALTER PROCEDURE [dbo].[netFindContentCoreDataByContentGuid]
	@ContentGuid UNIQUEIDENTIFIER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON

        --- *** use NOLOCK since this may be called during page save if debugging. The code should not be written so this happens, it's to make it work in the debugger ***
	SELECT TOP 1 P.pkID as ID, P.fkContentTypeID as ContentTypeID, P.fkParentID as ParentID, P.ContentGUID, PL.LinkURL, P.Deleted, CASE WHEN Status = 4 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS PendingPublish, PL.Created, PL.Changed, PL.Saved, PL.StartPublish, PL.StopPublish, P.ContentAssetsID, P.fkMasterLanguageBranchID as MasterLanguageBranchID, PL.ContentLinkGUID as ContentLinkID, PL.AutomaticLink, PL.FetchData, P.ContentType
	FROM tblContent AS P WITH (NOLOCK)
	LEFT JOIN tblContentLanguage AS PL ON PL.fkContentID=P.pkID
	WHERE P.ContentGUID = @ContentGuid AND (P.fkMasterLanguageBranchID=PL.fkLanguageBranchID OR P.fkMasterLanguageBranchID IS NULL)
END
GO
PRINT N'Altering [dbo].[netFindContentCoreDataByID]...';


GO
ALTER PROCEDURE [dbo].[netFindContentCoreDataByID]
	@ContentID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON

        --- *** use NOLOCK since this may be called during content save if debugging. The code should not be written so this happens, it's to make it work in the debugger ***
	SELECT TOP 1 P.pkID as ID, P.fkContentTypeID as ContentTypeID, P.fkParentID as ParentID, P.ContentGUID, PL.LinkURL, P.Deleted, CASE WHEN Status = 4 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS PendingPublish, PL.Created, PL.Changed, PL.Saved, PL.StartPublish, PL.StopPublish, P.ContentAssetsID, P.fkMasterLanguageBranchID as MasterLanguageBranchID, PL.ContentLinkGUID as ContentLinkID, PL.AutomaticLink, PL.FetchData, P.ContentType
	FROM tblContent AS P WITH (NOLOCK)
	LEFT JOIN tblContentLanguage AS PL ON PL.fkContentID = P.pkID
	WHERE P.pkID = @ContentID AND (P.fkMasterLanguageBranchID = PL.fkLanguageBranchID OR P.fkMasterLanguageBranchID IS NULL)
END
GO
PRINT N'Altering [dbo].[netPropertySearchValueMeta]...';


GO
ALTER PROCEDURE [dbo].[netPropertySearchValueMeta]
(
	@PageID			INT,
	@PropertyName 	NVARCHAR(255),
	@Equals			BIT = 0,
	@NotEquals		BIT = 0,
	@GreaterThan	BIT = 0,
	@LessThan		BIT = 0,
	@Boolean		BIT = NULL,
	@Number			INT = NULL,
	@FloatNumber	FLOAT = NULL,
	@PageType		INT = NULL,
	@PageLink		INT = NULL,
	@Date			DATETIME = NULL,
	@LanguageBranch	NCHAR(17) = NULL
)
AS
BEGIN
	DECLARE @LangBranchID NCHAR(17)
	SELECT @LangBranchID=pkID FROM tblLanguageBranch WHERE LanguageID=@LanguageBranch
	IF @LangBranchID IS NULL 
	BEGIN 
		if @LanguageBranch IS NOT NULL
			RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)
		else
			SET @LangBranchID = -1
	END
	
	DECLARE @DynSql NVARCHAR(2000)
	DECLARE @compare NVARCHAR(2)
	
	IF (@Equals = 1)
	BEGIN
	    SET @compare = '='
	END
	ELSE IF (@GreaterThan = 1)
	BEGIN
	    SET @compare = '>'
	END
	ELSE IF (@LessThan = 1)
	BEGIN
	    SET @compare = '<'
	END
	ELSE IF (@NotEquals = 1)
	BEGIN
	    SET @compare = '<>'
	END
	ELSE
	BEGIN
	    RAISERROR('No compare condition is defined.',16,1)
	END
	
	SET @DynSql = 'SELECT PageLanguages.fkPageID FROM tblPageLanguage as PageLanguages INNER JOIN tblTree ON tblTree.fkChildID=PageLanguages.fkPageID INNER JOIN tblContent as Pages ON Pages.pkID=PageLanguages.fkPageID'

	IF (@PropertyName = 'PageArchiveLink')
	BEGIN
		SET @DynSql = @DynSql + ' LEFT OUTER JOIN tblContent as Pages2 ON Pages.ArchiveContentGUID = Pages2.ContentGUID'
	END
	
	IF (@PropertyName = 'PageShortcutLink')
	BEGIN
		SET @DynSql = @DynSql + ' LEFT OUTER JOIN tblContent as Pages2 ON PageLanguages.PageLinkGUID = Pages2.ContentGUID'
	END
	
	SET @DynSql = @DynSql + ' WHERE Pages.ContentType = 0 AND tblTree.fkParentID=@PageID'

	IF (@LangBranchID <> -1)
	BEGIN
	    SET @DynSql = @DynSql + ' AND PageLanguages.fkLanguageBranchID=@LangBranchID'
	END
	
	IF (@PropertyName = 'PageVisibleInMenu')
	BEGIN
	    SET @DynSql = @DynSql + ' AND Pages.VisibleInMenu=@Boolean'
	END
	ELSE IF (@PropertyName = 'PageTypeID')
	BEGIN
	    IF (@Equals=1)
	        SET @DynSql = @DynSql + ' AND (Pages.fkContentTypeID = @PageType OR (@PageType IS NULL AND Pages.fkContentTypeID IS NULL))'
	    ELSE
	        SET @DynSql = @DynSql + ' AND (Pages.fkContentTypeID' + @compare + '@PageType OR (@PageType IS NULL AND NOT Pages.fkContentTypeID IS NULL))'
	END
	ELSE IF (@PropertyName = 'PageLink')
	BEGIN
	    IF (@Equals=1)
	        SET @DynSql = @DynSql + ' AND (PageLanguages.fkPageID = @PageLink OR (@PageLink IS NULL AND PageLanguages.fkPageID IS NULL))'
	    ELSE
	        SET @DynSql = @DynSql + ' AND (PageLanguages.fkPageID' + @compare + '@PageLink OR (@PageLink IS NULL AND NOT PageLanguages.fkPageID IS NULL))'
	END
	ELSE IF (@PropertyName = 'PageParentLink')
	BEGIN
	    IF (@Equals=1)
	        SET @DynSql = @DynSql + ' AND (Pages.fkParentID = @PageLink OR (@PageLink IS NULL AND Pages.fkParentID IS NULL))'
	    ELSE
	        SET @DynSql = @DynSql + ' AND (Pages.fkParentID' + @compare + '@PageLink OR (@PageLink IS NULL AND NOT Pages.fkParentID IS NULL))'
	END
	ELSE IF (@PropertyName = 'PageShortcutLink')
	BEGIN
		SET @DynSql = @DynSql + ' AND (Pages2.pkID' + @compare + '@PageLink OR (@PageLink IS NULL AND NOT PageLanguages.PageLinkGUID IS NULL))'
	END
	ELSE IF (@PropertyName = 'PageArchiveLink')
	BEGIN
		SET @DynSql = @DynSql + ' AND (Pages2.pkID' + @compare + '@PageLink OR (@PageLink IS NULL AND NOT Pages.ArchiveContentGUID IS NULL))'
	END
	ELSE IF (@PropertyName = 'PageChanged')
	BEGIN
	    IF (@Equals=1)
	        SET @DynSql = @DynSql + ' AND (PageLanguages.Changed = @Date OR (@Date IS NULL AND PageLanguages.Changed IS NULL))'
	    ELSE
	        SET @DynSql = @DynSql + ' AND (PageLanguages.Changed' + @compare + '@Date OR (@Date IS NULL AND NOT PageLanguages.Changed IS NULL))'
	END
	ELSE IF (@PropertyName = 'PageCreated')
	BEGIN
	    IF (@Equals=1)
	        SET @DynSql = @DynSql + ' AND (PageLanguages.Created = @Date OR (@Date IS NULL AND PageLanguages.Created IS NULL))'
	    ELSE
	        SET @DynSql = @DynSql + ' AND (PageLanguages.Created' + @compare + '@Date OR (@Date IS NULL AND NOT PageLanguages.Created IS NULL))'
	END
	ELSE IF (@PropertyName = 'PageSaved')
	BEGIN
	    IF (@Equals=1)
	        SET @DynSql = @DynSql + ' AND (PageLanguages.Saved = @Date OR (@Date IS NULL AND PageLanguages.Saved IS NULL))'
	    ELSE
	        SET @DynSql = @DynSql + ' AND (PageLanguages.Saved' + @compare + '@Date  OR (@Date IS NULL AND NOT PageLanguages.Saved IS NULL))'
	END
	ELSE IF (@PropertyName = 'PageStartPublish')
	BEGIN
	    IF (@Equals=1)
	        SET @DynSql = @DynSql + ' AND (PageLanguages.StartPublish = @Date OR (@Date IS NULL AND PageLanguages.StartPublish IS NULL))'
	    ELSE
	        SET @DynSql = @DynSql + ' AND (PageLanguages.StartPublish' + @compare + '@Date OR (@Date IS NULL AND NOT PageLanguages.StartPublish IS NULL))'
	END
	ELSE IF (@PropertyName = 'PageStopPublish')
	BEGIN
	    IF (@Equals=1)
	        SET @DynSql = @DynSql + ' AND (PageLanguages.StopPublish = @Date OR (@Date IS NULL AND PageLanguages.StopPublish IS NULL))'
	    ELSE
	        SET @DynSql = @DynSql + ' AND (PageLanguages.StopPublish' + @compare + '@Date OR (@Date IS NULL AND NOT PageLanguages.StopPublish IS NULL))'
	END
	ELSE IF (@PropertyName = 'PageDeleted')
	BEGIN
		SET @DynSql = @DynSql + ' AND Pages.Deleted = @Boolean'
	END
	ELSE IF (@PropertyName = 'PagePendingPublish')
	BEGIN
		SET @DynSql = @DynSql + ' AND PageLanguages.PendingPublish = @Boolean'
	END
	ELSE IF (@PropertyName = 'PageShortcutType')
	BEGIN
	    IF (@Number=0)
	        SET @DynSql = @DynSql + ' AND PageLanguages.AutomaticLink=1 AND PageLanguages.PageLinkGUID IS NULL'
	    ELSE IF (@Number=1)
	        SET @DynSql = @DynSql + ' AND PageLanguages.AutomaticLink=1 AND NOT PageLanguages.PageLinkGUID IS NULL AND PageLanguages.FetchData=0'
	    ELSE IF (@Number=2)
	        SET @DynSql = @DynSql + ' AND PageLanguages.AutomaticLink=0 AND PageLanguages.LinkURL<>N''#'''
	    ELSE IF (@Number=3)
	        SET @DynSql = @DynSql + ' AND PageLanguages.AutomaticLink=0 AND PageLanguages.LinkURL=N''#'''
	    ELSE IF (@Number=4)
	        SET @DynSql = @DynSql + ' AND PageLanguages.AutomaticLink=1 AND PageLanguages.FetchData=1'
	END

	EXEC sp_executesql @DynSql, 
		N'@PageID INT, @LangBranchID NCHAR(17), @Boolean BIT, @Number INT, @PageType INT, @PageLink INT, @Date DATETIME',
		@PageID=@PageID,
		@LangBranchID=@LangBranchID, 
		@Boolean=@Boolean,
		@Number=@Number,
		@PageType=@PageType,
		@PageLink=@PageLink,
		@Date=@Date
END
GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7022
GO
PRINT N'Refreshing [dbo].[editCreateContentVersion]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editCreateContentVersion]';


GO
PRINT N'Refreshing [dbo].[editPublishContentVersion]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editPublishContentVersion]';


GO
PRINT N'Refreshing [dbo].[netCategoryContentLoad]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netCategoryContentLoad]';


GO
PRINT N'Refreshing [dbo].[netContentChildrenReferences]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netContentChildrenReferences]';


GO
PRINT N'Refreshing [dbo].[netContentCreateLanguage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netContentCreateLanguage]';


GO
PRINT N'Refreshing [dbo].[netContentListOwnedAssetFolders]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netContentListOwnedAssetFolders]';


GO
PRINT N'Refreshing [dbo].[netContentMatchSegment]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netContentMatchSegment]';


GO
PRINT N'Refreshing [dbo].[netContentMove]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netContentMove]';


GO
PRINT N'Refreshing [dbo].[netContentRootList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netContentRootList]';


GO
PRINT N'Refreshing [dbo].[netContentTypeDelete]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netContentTypeDelete]';


GO
PRINT N'Refreshing [dbo].[netPersonalNotReadyList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPersonalNotReadyList]';


GO
PRINT N'Refreshing [dbo].[netPersonalRejectedList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPersonalRejectedList]';


GO
PRINT N'Refreshing [dbo].[netPropertyDefinitionGetUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertyDefinitionGetUsage]';


GO
PRINT N'Refreshing [dbo].[netPropertySearchCategoryMeta]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertySearchCategoryMeta]';


GO
PRINT N'Refreshing [dbo].[netPropertySearchString]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertySearchString]';


GO
PRINT N'Refreshing [dbo].[netReadyToPublishList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netReadyToPublishList]';


GO
PRINT N'Refreshing [dbo].[netSoftLinkList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netSoftLinkList]';


GO
PRINT N'Refreshing [dbo].[admDatabaseStatistics]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[admDatabaseStatistics]';


GO
PRINT N'Refreshing [dbo].[editDeletePageCheckInternal]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeletePageCheckInternal]';


GO
PRINT N'Refreshing [dbo].[editDeletePageInternal]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeletePageInternal]';


GO
PRINT N'Refreshing [dbo].[netConvertPageType]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netConvertPageType]';


GO
PRINT N'Refreshing [dbo].[netConvertPropertyForPageType]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netConvertPropertyForPageType]';


GO
PRINT N'Refreshing [dbo].[netCreatePath]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netCreatePath]';


GO
PRINT N'Refreshing [dbo].[netDynamicPropertiesLoad]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netDynamicPropertiesLoad]';


GO
PRINT N'Refreshing [dbo].[netPageChangeMasterLanguage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageChangeMasterLanguage]';


GO
PRINT N'Refreshing [dbo].[netPageCountDescendants]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageCountDescendants]';


GO
PRINT N'Refreshing [dbo].[netPageDefinitionDynamicCheck]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageDefinitionDynamicCheck]';


GO
PRINT N'Refreshing [dbo].[netPageDefinitionSave]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageDefinitionSave]';


GO
PRINT N'Refreshing [dbo].[netPageDeleteLanguage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageDeleteLanguage]';


GO
PRINT N'Refreshing [dbo].[netPageListAll]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageListAll]';


GO
PRINT N'Refreshing [dbo].[netPageListByLanguage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageListByLanguage]';


GO
PRINT N'Refreshing [dbo].[netPagePath]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPagePath]';


GO
PRINT N'Refreshing [dbo].[netPageTypeCheckUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageTypeCheckUsage]';


GO
PRINT N'Refreshing [dbo].[netPageTypeGetUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageTypeGetUsage]';


GO
PRINT N'Refreshing [dbo].[netPersonalActivityList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPersonalActivityList]';


GO
PRINT N'Refreshing [dbo].[netPropertySearch]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertySearch]';


GO
PRINT N'Refreshing [dbo].[netPropertySearchNull]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertySearchNull]';


GO
PRINT N'Refreshing [dbo].[netQuickSearchByExternalUrl]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netQuickSearchByExternalUrl]';


GO
PRINT N'Refreshing [dbo].[netQuickSearchByPath]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netQuickSearchByPath]';


GO
PRINT N'Refreshing [dbo].[netReportReadyToPublish]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netReportReadyToPublish]';


GO
PRINT N'Refreshing [dbo].[netReportSimpleAddresses]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netReportSimpleAddresses]';


GO
PRINT N'Refreshing [dbo].[netSubscriptionListRoots]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netSubscriptionListRoots]';


GO
PRINT N'Refreshing [dbo].[netContentEnsureVersions]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netContentEnsureVersions]';


GO
PRINT N'Refreshing [dbo].[editContentVersionList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editContentVersionList]';


GO
PRINT N'Refreshing [dbo].[editDeleteChilds]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeleteChilds]';


GO
PRINT N'Refreshing [dbo].[editDeletePage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeletePage]';


GO
PRINT N'Refreshing [dbo].[editDeleteChildsCheck]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeleteChildsCheck]';


GO
PRINT N'Refreshing [dbo].[editDeletePageCheck]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeletePageCheck]';


GO
PRINT N'Update complete.';


GO
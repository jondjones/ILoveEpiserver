--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7037)
				select 0, 'Already correct database version'
            else if (@ver = 7036)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery


GO
PRINT N'Dropping [dbo].[editCreateContentVersion]...';

GO
DROP PROCEDURE [dbo].[editCreateContentVersion];

GO
PRINT N'Dropping [dbo].[editContentVersionList]...';

GO
DROP PROCEDURE [dbo].[editContentVersionList];


GO
PRINT N'Dropping [dbo].[netDelayPublishList]...';


GO
DROP PROCEDURE [dbo].[netDelayPublishList];


GO
PRINT N'Dropping [dbo].[netPersonalActivityList]...';


GO
DROP PROCEDURE [dbo].[netPersonalActivityList];


GO
PRINT N'Dropping [dbo].[netPersonalNotReadyList]...';


GO
DROP PROCEDURE [dbo].[netPersonalNotReadyList];


GO
PRINT N'Dropping [dbo].[netPersonalRejectedList]...';


GO
DROP PROCEDURE [dbo].[netPersonalRejectedList];


GO
PRINT N'Dropping [dbo].[netReadyToPublishList]...';


GO
DROP PROCEDURE [dbo].[netReadyToPublishList];

GO
PRINT N'Dropping [dbo].[editDeletePageVersion]...';


GO
DROP PROCEDURE [dbo].[editDeletePageVersion];


GO
PRINT N'Dropping [dbo].[editDeletePageVersionInternal]...';


GO
DROP PROCEDURE [dbo].[editDeletePageVersionInternal];


GO
PRINT N'Dropping [dbo].[netPageDeleteLanguage]...';


GO
DROP PROCEDURE [dbo].[netPageDeleteLanguage];

GO
PRINT N'Dropping [dbo].[editPublishContentVersion]...';

GO
DROP PROCEDURE [dbo].[editPublishContentVersion];

GO
PRINT N'Dropping [dbo].[editSaveContentVersionData]...';

GO
DROP PROCEDURE [dbo].[editSaveContentVersionData];

GO
PRINT N'Creating [dbo].[tblWorkContent].[IDX_tblWorkContent_fkLanguageBranchID]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblWorkContent_fkLanguageBranchID]
    ON [dbo].[tblWorkContent]([fkLanguageBranchID] ASC);


GO
PRINT N'Creating [dbo].[netVersionFilterList]...';


GO
CREATE PROCEDURE [dbo].[netVersionFilterList]
(
    @StartIndex INT,
    @MaxRows INT,
	@ContentID INT = NULL,
	@ChangedBy NVARCHAR(255) = NULL,
	@ExcludeDeleted BIT = 0,
	@LanguageIds dbo.IDTable READONLY,
	@Statuses dbo.IDTable READONLY
)
AS

BEGIN	
	SET NOCOUNT ON

	DECLARE @StatusCount INT
	SELECT @StatusCount = COUNT(*) FROM @Statuses

	DECLARE @LanguageCount INT
	SELECT @LanguageCount = COUNT(*) FROM @LanguageIds;
	
	WITH TempResult as
	(
		SELECT ROW_NUMBER() OVER(ORDER BY W.Saved DESC) as RowNumber,
			W.fkContentID AS ContentID,
			W.pkID AS WorkID,
			W.Status AS VersionStatus,
			W.ChangedByName AS SavedBy,
			W.Saved AS ItemCreated,
			W.Name,
			W.fkLanguageBranchID as LanguageBranchID,
			W.CommonDraft,
			W.fkMasterVersionID as MasterVersion,
			CASE WHEN C.fkMasterLanguageBranchID=W.fkLanguageBranchID THEN 1 ELSE 0 END AS IsMasterLanguageBranch,
			W.NewStatusByName As StatusChangedBy,
			W.DelayPublishUntil
		FROM
			tblWorkContent AS W
			INNER JOIN
			tblContent AS C ON C.pkID=W.fkContentID
		WHERE
			((@ContentID IS NULL) OR W.fkContentID=@ContentID) AND
			((@ChangedBy IS NULL) OR W.ChangedByName=@ChangedBy) AND
			((@StatusCount = 0) OR (W.Status IN (SELECT ID FROM @Statuses))) AND
            ((@LanguageCount = 0) OR (W.fkLanguageBranchID IN (SELECT ID FROM @LanguageIds))) AND
			((@ExcludeDeleted = 0) OR (C.Deleted = 0))
	)
	SELECT  ContentID, WorkID, VersionStatus, SavedBy, ItemCreated, Name, LanguageBranchID, CommonDraft, MasterVersion, IsMasterLanguageBranch, StatusChangedBy, DelayPublishUntil, (SELECT COUNT(*) FROM TempResult) AS 'TotalRows'
	FROM    TempResult
	WHERE RowNumber BETWEEN (@StartIndex +1) AND (@MaxRows + @StartIndex)
   		
END
GO

PRINT N'Creating [dbo].[editCreateContentVersion]...';
GO

CREATE PROCEDURE [dbo].[editCreateContentVersion]
(
	@ContentID			INT,
	@WorkContentID		INT,
	@UserName		NVARCHAR(255),
	@MaxVersions	INT = NULL,
	@SavedDate		DATETIME,
	@LanguageBranch	NCHAR(17)
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @NewWorkContentID		INT
	DECLARE @DeleteWorkContentID	INT
	DECLARE @ObsoleteVersions	INT
	DECLARE @retval				INT
	DECLARE @IsMasterLang		BIT
	DECLARE @LangBranchID		INT
	
	SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID=@LanguageBranch
	IF @LangBranchID IS NULL
	BEGIN
		RAISERROR (N'editCreateContentVersion: LanguageBranchID is null, possibly empty table tblLanguageBranch', 16, 1, @WorkContentID)
		RETURN 0
	END

	IF (@WorkContentID IS NULL OR @WorkContentID=0 )
	BEGIN
		/* If we have a published version use it, else the latest saved version */
		IF EXISTS(SELECT * FROM tblContentLanguage WHERE Status = 4 AND fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID)
			SELECT @WorkContentID=[Version] FROM tblContentLanguage WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID
		ELSE
			SELECT TOP 1 @WorkContentID=pkID FROM tblWorkContent WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID ORDER BY Saved DESC
	END

	IF EXISTS( SELECT * FROM tblContent WHERE pkID=@ContentID AND fkMasterLanguageBranchID IS NULL )
		UPDATE tblContent SET fkMasterLanguageBranchID=@LangBranchID WHERE pkID=@ContentID
	
	SELECT @IsMasterLang = CASE WHEN @LangBranchID=fkMasterLanguageBranchID THEN 1 ELSE 0 END FROM tblContent WHERE pkID=@ContentID
		
		/* Create a new version of this content */
		INSERT INTO tblWorkContent
			(fkContentID,
			fkMasterVersionID,
			ChangedByName,
			ContentLinkGUID,
			fkFrameID,
			ArchiveContentGUID,
			Name,
			LinkURL,
			ExternalURL,
			VisibleInMenu,
			LinkType,
			Created,
			Saved,
			StartPublish,
			StopPublish,
			ChildOrderRule,
			PeerOrder,
			fkLanguageBranchID,
			URLSegment)
		SELECT 
			fkContentID,
			@WorkContentID,
			@UserName,
			ContentLinkGUID,
			fkFrameID,
			ArchiveContentGUID,
			Name,
			LinkURL,
			ExternalURL,
			VisibleInMenu,
			LinkType,
			Created,
			@SavedDate,
			StartPublish,
			StopPublish,
			ChildOrderRule,
			PeerOrder,
			@LangBranchID,
			URLSegment
		FROM 
			tblWorkContent 
		WHERE 
			pkID=@WorkContentID
	
		IF (@@ROWCOUNT = 1)
		BEGIN
			/* Remember version number */
			SET @NewWorkContentID= SCOPE_IDENTITY() 
			/* Copy all properties as well */
			INSERT INTO tblWorkContentProperty
				(fkPropertyDefinitionID,
				fkWorkContentID,
				ScopeName,
				Boolean,
				Number,
				FloatNumber,
				ContentType,
				ContentLink,
				Date,
				String,
				LongString,
                LinkGuid)          
			SELECT
				fkPropertyDefinitionID,
				@NewWorkContentID,
				ScopeName,
				Boolean,
				Number,
				FloatNumber,
				ContentType,
				ContentLink,
				Date,
				String,
				LongString,
                LinkGuid
			FROM
				tblWorkContentProperty
			INNER JOIN tblPropertyDefinition ON tblPropertyDefinition.pkID=tblWorkContentProperty.fkPropertyDefinitionID
			WHERE
				fkWorkContentID=@WorkContentID
				AND (tblPropertyDefinition.LanguageSpecific>2 OR @IsMasterLang=1)--Only lang specific on non-master 
				
			/* Finally take care of categories */
			INSERT INTO tblWorkContentCategory
				(fkWorkContentID,
				fkCategoryID,
				CategoryType,
				ScopeName)
			SELECT
				@NewWorkContentID,
				fkCategoryID,
				CategoryType,
				ScopeName
			FROM
				tblWorkContentCategory
			WHERE
				fkWorkContentID=@WorkContentID
				AND (CategoryType<>0 OR @IsMasterLang=1)--No content category on languages
		END
		ELSE
		BEGIN
			/* We did not have anything corresponding to the WorkContentID, create new work content from tblContent */
			INSERT INTO tblWorkContent
				(fkContentID,
				ChangedByName,
				ContentLinkGUID,
				fkFrameID,
				ArchiveContentGUID,
				Name,
				LinkURL,
				ExternalURL,
				VisibleInMenu,
				LinkType,
				Created,
				Saved,
				StartPublish,
				StopPublish,
				ChildOrderRule,
				PeerOrder,
				fkLanguageBranchID,
				URLSegment)
			SELECT 
				@ContentID,
				COALESCE(@UserName, tblContentLanguage.CreatorName),
				tblContentLanguage.ContentLinkGUID,
				tblContentLanguage.fkFrameID,
				tblContent.ArchiveContentGUID,
				tblContentLanguage.Name,
				tblContentLanguage.LinkURL,
				tblContentLanguage.ExternalURL,
				tblContent.VisibleInMenu,
				CASE tblContentLanguage.AutomaticLink 
					WHEN 1 THEN 
						(CASE
							WHEN tblContentLanguage.ContentLinkGUID IS NULL THEN 0	/* EPnLinkNormal */
							WHEN tblContentLanguage.FetchData=1 THEN 4				/* EPnLinkFetchdata */
							ELSE 1								/* EPnLinkShortcut */
						END)
					ELSE
						(CASE 
							WHEN tblContentLanguage.LinkURL=N'#' THEN 3				/* EPnLinkInactive */
							ELSE 2								/* EPnLinkExternal */
						END)
				END AS LinkType ,
				tblContentLanguage.Created,
				@SavedDate,
				tblContentLanguage.StartPublish,
				tblContentLanguage.StopPublish,
				tblContent.ChildOrderRule,
				tblContent.PeerOrder,
				@LangBranchID,
				tblContentLanguage.URLSegment
			FROM tblContentLanguage
			INNER JOIN tblContent ON tblContent.pkID=tblContentLanguage.fkContentID
			WHERE 
				tblContentLanguage.fkContentID=@ContentID AND tblContentLanguage.fkLanguageBranchID=@LangBranchID

			IF (@@ROWCOUNT = 1)
			BEGIN
				/* Remember version number */
				SET @NewWorkContentID= SCOPE_IDENTITY() 
				/* Copy all non-dynamic properties as well */
				INSERT INTO tblWorkContentProperty
					(fkPropertyDefinitionID,
					fkWorkContentID,
					ScopeName,
					Boolean,
					Number,
					FloatNumber,
					ContentType,
					ContentLink,
					Date,
					String,
					LongString,
                    LinkGuid)
				SELECT
					P.fkPropertyDefinitionID,
					@NewWorkContentID,
					P.ScopeName,
					P.Boolean,
					P.Number,
					P.FloatNumber,
					P.ContentType,
					P.ContentLink,
					P.Date,
					P.String,
					P.LongString,
                    P.LinkGuid
				FROM
					tblContentProperty AS P
				INNER JOIN
					tblPropertyDefinition AS PD ON P.fkPropertyDefinitionID=PD.pkID
				WHERE
					P.fkContentID=@ContentID AND (PD.fkContentTypeID IS NOT NULL)
					AND P.fkLanguageBranchID = @LangBranchID
					AND (PD.LanguageSpecific>2 OR @IsMasterLang=1)--Only lang specific on non-master 
					
				/* Finally take care of categories */
				INSERT INTO tblWorkContentCategory
					(fkWorkContentID,
					fkCategoryID,
					CategoryType)
				SELECT DISTINCT
					@NewWorkContentID,
					fkCategoryID,
					CategoryType
				FROM
					tblContentCategory
				LEFT JOIN
					tblPropertyDefinition AS PD ON tblContentCategory.CategoryType = PD.pkID
				WHERE
					tblContentCategory.fkContentID=@ContentID 
					AND (PD.fkContentTypeID IS NOT NULL OR tblContentCategory.CategoryType = 0) --Not dynamic properties
					AND (PD.LanguageSpecific=1 OR @IsMasterLang=1) --No content category on languages
			END
			ELSE
			BEGIN
				RAISERROR (N'Failed to create new version for content %d', 16, 1, @ContentID)
				RETURN 0
			END
		END

	/*If there is no version set for tblContentLanguage set it to this version*/
	UPDATE tblContentLanguage SET Version = @NewWorkContentID
	WHERE fkContentID = @ContentID AND fkLanguageBranchID = @LangBranchID AND Version IS NULL
		
	RETURN @NewWorkContentID
END
GO

PRINT N'Creating [dbo].[editPublishContentVersion]...';
GO

CREATE PROCEDURE dbo.editPublishContentVersion
(
	@WorkContentID	INT,
	@UserName NVARCHAR(255),
	@MaxVersions INT = NULL,
	@ResetCommonDraft BIT = 1,
	@PublishedDate DATETIME = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @ContentID INT
	DECLARE @retval INT
	DECLARE @FirstPublish BIT
	DECLARE @ParentID INT
	DECLARE @LangBranchID INT
	DECLARE @IsMasterLang BIT
	
	/* Verify that we have a Content to publish */
	SELECT	@ContentID=fkContentID,
			@LangBranchID=fkLanguageBranchID,
			@IsMasterLang = CASE WHEN tblWorkContent.fkLanguageBranchID=tblContent.fkMasterLanguageBranchID THEN 1 ELSE 0 END
	FROM tblWorkContent WITH (ROWLOCK,XLOCK)
	INNER JOIN tblContent WITH (ROWLOCK,XLOCK) ON tblContent.pkID=tblWorkContent.fkContentID
	WHERE tblWorkContent.pkID=@WorkContentID
	
	IF (@@ROWCOUNT <> 1)
		RETURN 0

	IF @PublishedDate IS NULL
		SET @PublishedDate = GetDate()
					
	/* Move Content information from worktable to published table */
	IF @IsMasterLang=1
	BEGIN
		UPDATE 
			tblContent
		SET
			ArchiveContentGUID	= W.ArchiveContentGUID,
			VisibleInMenu	= W.VisibleInMenu,
			ChildOrderRule	= W.ChildOrderRule,
			PeerOrder		= W.PeerOrder
		FROM 
			tblWorkContent AS W
		WHERE 
			tblContent.pkID=W.fkContentID AND 
			W.pkID=@WorkContentID
	END
	
	UPDATE 
			tblContentLanguage WITH (ROWLOCK,XLOCK)
		SET
			ChangedByName	= W.ChangedByName,
			ContentLinkGUID	= W.ContentLinkGUID,
			fkFrameID		= W.fkFrameID,
			Name			= W.Name,
			URLSegment		= W.URLSegment,
			LinkURL			= W.LinkURL,
			BlobUri			= W.BlobUri,
			ThumbnailUri	= W.ThumbnailUri,
			ExternalURL		= Lower(W.ExternalURL),
			AutomaticLink	= CASE WHEN W.LinkType = 2 OR W.LinkType = 3 THEN 0 ELSE 1 END,
			FetchData		= CASE WHEN W.LinkType = 4 THEN 1 ELSE 0 END,
			Created			= W.Created,
			Changed			= CASE WHEN W.ChangedOnPublish=0 AND tblContentLanguage.Status = 4 THEN Changed ELSE @PublishedDate END,
			Saved			= @PublishedDate,
			StartPublish	= COALESCE(W.StartPublish, @PublishedDate),
			StopPublish		= W.StopPublish,
			Status			= 4,
			Version			= @WorkContentID,
			DelayPublishUntil = NULL
		FROM 
			tblWorkContent AS W
		WHERE 
			tblContentLanguage.fkContentID=W.fkContentID AND
			W.fkLanguageBranchID=tblContentLanguage.fkLanguageBranchID AND
			W.pkID=@WorkContentID

	IF @@ROWCOUNT!=1
		RAISERROR (N'editPublishContentVersion: Cannot find correct version in tblContentLanguage for version %d', 16, 1, @WorkContentID)

	/*Set current published version on this language to HasBeenPublished*/
	UPDATE
		tblWorkContent
	SET
		Status = 5
	WHERE
		fkContentID = @ContentID AND
		fkLanguageBranchID = @LangBranchID AND 
		Status = 4 AND
		pkID<>@WorkContentID

	/* Remember that this version has been published, and clear the delay publish date if used */
	UPDATE
		tblWorkContent
	SET
		Status = 4,
		ChangedOnPublish = 0,
		Saved=@PublishedDate,
		NewStatusByName=@UserName,
		fkMasterVersionID = NULL,
		DelayPublishUntil = NULL,
		StartPublish = COALESCE(StartPublish, @PublishedDate)
	WHERE
		pkID=@WorkContentID
		
	/* Remove all properties defined for this Content except dynamic properties */
	DELETE FROM 
		tblContentProperty
	FROM 
		tblContentProperty
	INNER JOIN
		tblPropertyDefinition ON fkPropertyDefinitionID=tblPropertyDefinition.pkID
	WHERE 
		fkContentID=@ContentID AND
		fkContentTypeID IS NOT NULL AND
		fkLanguageBranchID=@LangBranchID
		
	/* Move properties from worktable to published table */
	INSERT INTO tblContentProperty 
		(fkPropertyDefinitionID,
		fkContentID,
		fkLanguageBranchID,
		ScopeName,
		[guid],
		Boolean,
		Number,
		FloatNumber,
		ContentType,
		ContentLink,
		Date,
		String,
		LongString,
		LongStringLength,
        LinkGuid)
	SELECT
		fkPropertyDefinitionID,
		@ContentID,
		@LangBranchID,
		ScopeName,
		[guid],
		Boolean,
		Number,
		FloatNumber,
		ContentType,
		ContentLink,
		Date,
		String,
		LongString,
		/* LongString is utf-16 - Datalength gives bytes, i e div by 2 gives characters */
		/* Include length to handle delayed loading of LongString with threshold */
		COALESCE(DATALENGTH(LongString), 0) / 2,
        LinkGuid
	FROM
		tblWorkContentProperty
	WHERE
		fkWorkContentID=@WorkContentID
	
	/* Move categories to published tables */
	DELETE 	tblContentCategory
	FROM tblContentCategory
	LEFT JOIN tblPropertyDefinition ON tblPropertyDefinition.pkID=tblContentCategory.CategoryType 
	WHERE 	tblContentCategory.fkContentID=@ContentID
			AND (NOT fkContentTypeID IS NULL OR CategoryType=0)
			AND (tblPropertyDefinition.LanguageSpecific>2 OR @IsMasterLang=1)--Only lang specific on non-master
			AND tblContentCategory.fkLanguageBranchID=@LangBranchID
			
	INSERT INTO tblContentCategory
		(fkContentID,
		fkCategoryID,
		CategoryType,
		fkLanguageBranchID,
		ScopeName)
	SELECT
		@ContentID,
		fkCategoryID,
		CategoryType,
		@LangBranchID,
		ScopeName
	FROM
		tblWorkContentCategory
	WHERE
		fkWorkContentID=@WorkContentID
	
	
	EXEC netContentTrimVersions @ContentID=@ContentID, @MaxVersions=@MaxVersions

	IF @ResetCommonDraft = 1
		EXEC editSetCommonDraftVersion @WorkContentID = @WorkContentID, @Force = 1				

	RETURN 0
END
GO

PRINT N'Creating [dbo].[editSaveContentVersionData]...';
GO

CREATE PROCEDURE [dbo].[editSaveContentVersionData]
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
	@URLSegment			NVARCHAR(255)		= NULL,
	@SetStartPublish    BIT					= 1
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
			StartPublish		= CASE WHEN @SetStartPublish = 1 THEN @StartPublish ELSE StartPublish END,
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
				StartPublish	= CASE WHEN @SetStartPublish = 1 THEN @StartPublish ELSE StartPublish END,
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

PRINT N'Creating [dbo].[editDeleteContentVersionInternal]...';
GO

CREATE PROCEDURE dbo.editDeleteContentVersionInternal
(
	@WorkContentID		INT
)
AS
BEGIN
	UPDATE tblWorkContent SET fkMasterVersionID=NULL WHERE fkMasterVersionID=@WorkContentID
	DELETE FROM tblWorkContentProperty WHERE fkWorkContentID=@WorkContentID
	DELETE FROM tblWorkContentCategory WHERE fkWorkContentID=@WorkContentID
	DELETE FROM tblWorkContent WHERE pkID=@WorkContentID
	
	RETURN 0
END
GO
PRINT N'Creating [dbo].[netContentDeleteLanguage]...';


GO
CREATE PROCEDURE dbo.netContentDeleteLanguage
(
	@ContentID		INT,
	@LanguageBranch	NCHAR(17)
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @LangBranchID		INT
		
	SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID=@LanguageBranch
	IF @LangBranchID IS NULL
	BEGIN
		--Unknown language
		RETURN -1
	END

	IF EXISTS( SELECT * FROM tblPage WHERE pkID=@ContentID AND fkMasterLanguageBranchID=@LangBranchID )
	BEGIN
		--Cannot delete master language branch
		RETURN -2
	END

	IF NOT EXISTS( SELECT * FROM tblPageLanguage WHERE fkPageID=@ContentID AND fkLanguageBranchID=@LangBranchID )
	BEGIN
		--Language does not exist on content instance
		RETURN -3
	END

	UPDATE tblWorkContent SET fkMasterVersionID=NULL WHERE pkID IN (SELECT pkID FROM tblWorkContent WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID)
    
	DELETE FROM tblWorkContentProperty WHERE fkWorkContentID IN (SELECT pkID FROM tblWorkContent WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID)
	DELETE FROM tblWorkContentCategory WHERE fkWorkContentID IN (SELECT pkID FROM tblWorkContent WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID)
	DELETE FROM tblContentLanguage WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID
	DELETE FROM tblWorkContent WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID
	DELETE FROM tblContentSoftlink WHERE fkOwnerContentID =  @ContentID AND OwnerLanguageID = @LangBranchID

	DELETE FROM tblContentProperty FROM tblContentProperty
	INNER JOIN tblPropertyDefinition ON tblPropertyDefinition.pkID=tblContentProperty.fkPropertyDefinitionID
	WHERE fkContentID=@ContentID 
	AND fkLanguageBranchID=@LangBranchID
	AND fkContentTypeID IS NOT NULL
	
	DELETE FROM tblContentCategory WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID
		
	RETURN 1

END
GO
PRINT N'Creating [dbo].[editDeleteContentVersion]...';


GO
CREATE PROCEDURE dbo.editDeleteContentVersion
(
	@WorkContentID		INT
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @ContentID			INT
	DECLARE @PublishedWorkID	INT
	DECLARE @LangBranchID		INT
	
	/* Verify that we can delete this version (i e do not allow removal of current version) */
	SELECT 
		@ContentID=tblContentLanguage.fkContentID, 
		@LangBranchID=tblContentLanguage.fkLanguageBranchID,
		@PublishedWorkID=tblContentLanguage.[Version] 
	FROM 
		tblWorkContent 
	INNER JOIN 
		tblContentLanguage ON tblContentLanguage.fkContentID=tblWorkContent.fkContentID AND tblContentLanguage.fkLanguageBranchID = tblWorkContent.fkLanguageBranchID
	WHERE 
		tblWorkContent.pkID=@WorkContentID
		
	IF (@@ROWCOUNT <> 1 OR @PublishedWorkID=@WorkContentID)
		RETURN -1
	IF ( (SELECT COUNT(pkID) FROM tblWorkContent WHERE fkContentID=@ContentID AND fkLanguageBranchID=@LangBranchID ) < 2 )
		RETURN -1
		
	EXEC editDeleteContentVersionInternal @WorkContentID=@WorkContentID
	
	RETURN 0
END
GO
PRINT N'Altering [dbo].[netContentTrimVersions]...';


GO
ALTER PROCEDURE dbo.netContentTrimVersions
(
	@ContentID		INT,
	@MaxVersions	INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @ObsoleteVersions	INT
	DECLARE @DeleteWorkContentID	INT
	DECLARE @retval		INT
	DECLARE @CurrentLanguage 	INT
	DECLARE @FirstLanguage	BIT

	SET @FirstLanguage = 1
	
	IF (@MaxVersions IS NULL OR @MaxVersions=0)
		RETURN 0
		
		CREATE TABLE #languages (fkLanguageBranchID INT)
		INSERT INTO #languages SELECT DISTINCT(fkLanguageBranchID) FROM tblWorkContent WITH(INDEX(IDX_tblWorkContent_fkContentID)) WHERE fkContentID = @ContentID 
		SET @CurrentLanguage = (SELECT MIN(fkLanguageBranchID) FROM #languages)
		
		WHILE (NOT @CurrentLanguage = 0)
		BEGIN
			DECLARE @PublishedVersion INT
			SELECT @PublishedVersion = [Version] FROM tblContentLanguage WHERE fkContentID=@ContentID AND fkLanguageBranchID=@CurrentLanguage AND Status = 4
			SELECT @ObsoleteVersions = COUNT(pkID)+CASE WHEN @PublishedVersion IS NULL THEN 0 ELSE 1 END FROM tblWorkContent  WITH(NOLOCK) WHERE fkContentID=@ContentID AND Status = 5 AND fkLanguageBranchID=@CurrentLanguage AND pkID<>@PublishedVersion
			WHILE (@ObsoleteVersions > @MaxVersions)
			BEGIN
				SELECT TOP 1 @DeleteWorkContentID=pkID FROM tblWorkContent   WITH(NOLOCK) WHERE fkContentID=@ContentID AND Status = 5 AND fkLanguageBranchID=@CurrentLanguage AND pkID<>@PublishedVersion ORDER BY pkID ASC
				EXEC @retval=editDeleteContentVersion @WorkContentID=@DeleteWorkContentID
				IF (@retval <> 0)
					BREAK
				SET @ObsoleteVersions=@ObsoleteVersions - 1
			END
			IF EXISTS(SELECT fkLanguageBranchID FROM #languages WHERE fkLanguageBranchID > @CurrentLanguage)
			    SET @CurrentLanguage = (SELECT MIN(fkLanguageBranchID) FROM #languages WHERE fkLanguageBranchID > @CurrentLanguage)
		    ELSE
		        SET @CurrentLanguage = 0
		END
		
		DROP TABLE #languages
	
	RETURN 0
END
GO

PRINT N'Altering [dbo].[netPropertySearchString]...';
GO

ALTER PROCEDURE [dbo].[netPropertySearchString]
(
	@PageID				INT,
	@PropertyName 		NVARCHAR(255),
	@UseWildCardsBefore	BIT = 0,
	@UseWildCardsAfter	BIT = 0,
	@String				NVARCHAR(2000) = NULL,
	@LanguageBranch		NCHAR(17) = NULL
)
AS
BEGIN
	DECLARE @LangBranchID INT
	DECLARE @Path VARCHAR(7000)
	DECLARE @SearchString NVARCHAR(2002)
	SELECT @LangBranchID=pkID FROM tblLanguageBranch WHERE LanguageID=@LanguageBranch
	IF @LangBranchID IS NULL 
	BEGIN 
		if @LanguageBranch IS NOT NULL
			RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)
		else
			SET @LangBranchID = -1
	END
	SELECT @Path=PagePath + CONVERT(VARCHAR, @PageID) + '.' FROM tblPage WHERE pkID=@PageID
	SET @SearchString=CASE    
		WHEN @UseWildCardsBefore=0 AND @UseWildCardsAfter=0 THEN @String
		WHEN @UseWildCardsBefore=1 AND @UseWildCardsAfter=0 THEN '%' + @String
		WHEN @UseWildCardsBefore=0 AND @UseWildCardsAfter=1 THEN @String + '%'
		ELSE '%' + @String + '%'
	END
	
	IF @String IS NULL
		SELECT P.pkID
		FROM tblContent AS P
		INNER JOIN tblProperty ON tblProperty.fkPageID=P.pkID
		INNER JOIN tblPageLanguage ON tblPageLanguage.fkPageID=P.pkID
		INNER JOIN tblPageDefinition ON tblPageDefinition.pkID = tblProperty.fkPageDefinitionID and tblPageDefinition.Name = @PropertyName and tblPageDefinition.Property in (6,7)
		WHERE 
			P.ContentType = 0 
		AND
			P.ContentPath LIKE (@Path + '%')
		AND 
			(@LangBranchID=-1 OR tblProperty.fkLanguageBranchID=@LangBranchID OR tblPageDefinition.LanguageSpecific<3)
		AND 
			(String IS NULL AND LongString IS NULL)
	ELSE
		SELECT P.pkID
		FROM tblContent AS P
		INNER JOIN tblProperty ON tblProperty.fkPageID=P.pkID
		INNER JOIN tblPageLanguage ON tblPageLanguage.fkPageID=P.pkID
		INNER JOIN tblPageDefinition ON tblPageDefinition.pkID = tblProperty.fkPageDefinitionID and tblPageDefinition.Name = @PropertyName and tblPageDefinition.Property = 6
		WHERE 
			P.ContentType = 0 
		AND
			P.ContentPath LIKE (@Path + '%')
		AND 
			(@LangBranchID=-1 OR tblProperty.fkLanguageBranchID=@LangBranchID OR tblPageDefinition.LanguageSpecific<3)
		AND
			String LIKE @SearchString
		UNION
		SELECT P.pkID
		FROM tblContent AS P
		INNER JOIN tblProperty ON tblProperty.fkPageID=P.pkID
		INNER JOIN tblPageLanguage ON tblPageLanguage.fkPageID=P.pkID
		INNER JOIN tblPageDefinition ON tblPageDefinition.pkID = tblProperty.fkPageDefinitionID and tblPageDefinition.Name = @PropertyName and tblPageDefinition.Property = 7
		WHERE 
			P.ContentType = 0 
		AND
			P.ContentPath LIKE (@Path + '%')
		AND 
			(@LangBranchID=-1 OR tblProperty.fkLanguageBranchID=@LangBranchID OR tblPageDefinition.LanguageSpecific<3)
		AND
			LongString LIKE @SearchString
END
GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7037
GO

PRINT N'Update complete.';


GO

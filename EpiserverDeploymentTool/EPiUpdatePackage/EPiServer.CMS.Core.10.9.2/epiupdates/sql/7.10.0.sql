--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7008)
				select 0, 'Already correct database version'
            else if (@ver = 7007)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery


GO
PRINT N'Creating [dbo].[ContentReferenceTable]...';


GO
CREATE TYPE [dbo].[ContentReferenceTable] AS TABLE (
    [ID]       INT            NULL,
    [WorkID]   INT            NULL,
    [Provider] NVARCHAR (255) NULL);


GO
PRINT N'Creating [dbo].[IDTable]...';


GO
CREATE TYPE [dbo].[IDTable] AS TABLE (
    [ID] INT NOT NULL);


GO
PRINT N'Creating [dbo].[ProjectItemTable]...';


GO
CREATE TYPE [dbo].[ProjectItemTable] AS TABLE (
    [ID]                  INT            NULL,
    [ProjectID]           INT            NULL,
    [ContentLinkID]       INT            NULL,
    [ContentLinkWorkID]   INT            NULL,
    [ContentLinkProvider] NVARCHAR (255) NULL,
    [Language]            NVARCHAR (17)  NULL,
    [Category]            NVARCHAR (255) NULL);


GO
PRINT N'Creating [dbo].[ProjectMemberTable]...';


GO
CREATE TYPE [dbo].[ProjectMemberTable] AS TABLE (
    [ID]   INT           NULL,
    [Name] VARCHAR (255) NULL,
    [Type] SMALLINT      NULL);


GO
PRINT N'Altering [dbo].[tblContentLanguage]...';


GO
ALTER TABLE [dbo].[tblContentLanguage]
    ADD [DelayPublishUntil] DATETIME NULL;


GO
PRINT N'Altering [dbo].[tblWorkContent]...';


GO
ALTER TABLE [dbo].[tblWorkContent]
    ADD [DelayPublishUntil] DATETIME NULL;


GO
PRINT N'Creating [dbo].[tblProject]...';


GO
CREATE TABLE [dbo].[tblProject] (
    [pkID]                    INT            IDENTITY (1, 1) NOT NULL,
    [Name]                    NVARCHAR (255) NOT NULL,
    [IsPublic]                BIT            NOT NULL,
    [Created]                 DATETIME       NOT NULL,
    [CreatedBy]               NVARCHAR (255) NOT NULL,
    [Status]                  INT            NOT NULL,
    [PublishingTrackingToken] NVARCHAR (255) NULL,
    CONSTRAINT [PK_tblProject] PRIMARY KEY CLUSTERED ([pkID] ASC)
);


GO
PRINT N'Creating [dbo].[tblProject].[IX_tblProject_StatusName]...';


GO
CREATE NONCLUSTERED INDEX [IX_tblProject_StatusName]
    ON [dbo].[tblProject]([Status] ASC, [Name] ASC);


GO
PRINT N'Creating [dbo].[tblProjectItem]...';


GO
CREATE TABLE [dbo].[tblProjectItem] (
    [pkID]                INT            IDENTITY (1, 1) NOT NULL,
    [fkProjectID]         INT            NOT NULL,
    [ContentLinkID]       INT            NOT NULL,
    [ContentLinkWorkID]   INT            NOT NULL,
    [ContentLinkProvider] NVARCHAR (255) NOT NULL,
    [Language]            VARCHAR (17)   NOT NULL,
    [Category]            NVARCHAR (255) NOT NULL,
    CONSTRAINT [PK_tblProjectItem] PRIMARY KEY CLUSTERED ([pkID] ASC)
);


GO
PRINT N'Creating [dbo].[tblProjectItem].[IX_tblProjectItem_ContentLink]...';


GO
CREATE NONCLUSTERED INDEX [IX_tblProjectItem_ContentLink]
    ON [dbo].[tblProjectItem]([ContentLinkID] ASC, [ContentLinkProvider] ASC, [ContentLinkWorkID] ASC);


GO
PRINT N'Creating [dbo].[tblProjectItem].[IX_tblProjectItem_fkProjectID]...';


GO
CREATE NONCLUSTERED INDEX [IX_tblProjectItem_fkProjectID]
    ON [dbo].[tblProjectItem]([fkProjectID] ASC, [Category] ASC, [Language] ASC);


GO
PRINT N'Creating [dbo].[tblProjectMember]...';


GO
CREATE TABLE [dbo].[tblProjectMember] (
    [pkID]        INT            IDENTITY (1, 1) NOT NULL,
    [fkProjectID] INT            NOT NULL,
    [Name]        NVARCHAR (255) NOT NULL,
    [Type]        SMALLINT       NOT NULL,
    CONSTRAINT [PK_tblProjectMember] PRIMARY KEY CLUSTERED ([pkID] ASC)
);


GO
PRINT N'Creating [dbo].[tblProjectMember].[IX_tblProjectMember_fkProjectID]...';


GO
CREATE NONCLUSTERED INDEX [IX_tblProjectMember_fkProjectID]
    ON [dbo].[tblProjectMember]([fkProjectID] ASC);


GO
PRINT N'Creating FK_tblProjectItem_tblProject...';


GO
ALTER TABLE [dbo].[tblProjectItem] WITH NOCHECK
    ADD CONSTRAINT [FK_tblProjectItem_tblProject] FOREIGN KEY ([fkProjectID]) REFERENCES [dbo].[tblProject] ([pkID]);


GO
PRINT N'Creating FK_tblProjectMember_tblProject...';


GO
ALTER TABLE [dbo].[tblProjectMember] WITH NOCHECK
    ADD CONSTRAINT [FK_tblProjectMember_tblProject] FOREIGN KEY ([fkProjectID]) REFERENCES [dbo].[tblProject] ([pkID]);


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
	@FolderID			INT					= NULL,
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
	DECLARE @ExternalFolderID		INT
	DECLARE @AssetsID				UNIQUEIDENTIFIER
	DECLARE @OwnerID				UNIQUEIDENTIFIER
	DECLARE @CurrentLangBranchID	INT
	DECLARE @IsMasterLang			BIT
	
	/* Pull some useful information from the published Content */
	SELECT
		@ContentID				= fkContentID,
		@ParentID				= fkParentID,
		@ContentTypeID			= fkContentTypeID,
		@ExternalFolderID		= ExternalFolderID,
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
			
		/* Special case for handling external folder id. Only set new value if */
		/* current value of ExternalFolderID is null */
		IF ((@ExternalFolderID IS NULL) AND (@FolderID IS NOT NULL))
		BEGIN
			UPDATE
				tblContent
			SET
				ExternalFolderID=@FolderID
			WHERE
				pkID=@ContentID
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
PRINT N'Altering [dbo].[editSetVersionStatus]...';


GO
ALTER PROCEDURE [dbo].[editSetVersionStatus]
(
	@WorkContentID INT,
	@Status INT,
	@UserName NVARCHAR(255),
	@Saved DATETIME = NULL,
	@RejectComment NVARCHAR(2000) = NULL,
	@DelayPublishUntil DateTime = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	UPDATE 
		tblWorkContent
	SET
		Status = @Status,
		NewStatusByName=@UserName,
		RejectComment= COALESCE(@RejectComment, RejectComment),
		Saved = COALESCE(@Saved, Saved),
		DelayPublishUntil = @DelayPublishUntil
	WHERE
		pkID=@WorkContentID 

	IF (@@ROWCOUNT = 0)
		RETURN 1

	-- If there is no published version for this language update published table as well
	DECLARE @ContentId INT;
	DECLARE @LanguageBranchID INT;

	SELECT @LanguageBranchID = lang.fkLanguageBranchID, @ContentId = lang.fkContentID FROM tblContentLanguage AS lang INNER JOIN tblWorkContent AS work 
		ON lang.fkContentID = work.fkContentID WHERE 
		work.pkID = @WorkContentID AND work.fkLanguageBranchID = lang.fkLanguageBranchID AND lang.Status <> 4

	IF @ContentId IS NOT NULL
		BEGIN

			UPDATE
				tblContentLanguage
			SET
				Status = @Status,
				DelayPublishUntil = @DelayPublishUntil
			WHERE
				fkContentID=@ContentID AND fkLanguageBranchID=@LanguageBranchID

		END

	RETURN 0
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
		ExternalFolderID AS PageFolderID,
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
		ContentLink AS PageLinkID,
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
		ContentLink AS PageLinkID,
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
PRINT N'Altering [dbo].[netDelayPublishList]...';


GO
ALTER PROCEDURE dbo.netDelayPublishList
(
	@UntilDate	DATETIME,
	@ContentID		INT
)
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		fkContentID AS ContentID,
		pkID AS ContentWorkID,
		DelayPublishUntil
	FROM
		tblWorkContent
	WHERE
		Status = 6 AND
		DelayPublishUntil <= @UntilDate AND
		(fkContentID = @ContentID OR @ContentID IS NULL)
	ORDER BY
		DelayPublishUntil
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
		ExternalFolderID AS PageFolderID,
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
		PageLink AS PageLinkID,
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

	DECLARE @ContentItems TABLE (LocalPageID INT)
	DECLARE	@Length SMALLINT
	DECLARE @Index SMALLINT
	SET @Index = 1
	SET @Length = DATALENGTH(@Binary)
	WHILE (@Index <= @Length)
	BEGIN
		INSERT INTO @ContentItems VALUES(SUBSTRING(@Binary, @Index, 4))
		SET @Index = @Index + 4
	END

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
	WHERE 
		L.fkLanguageBranchID = @LanguageBranchID
	OR
		L.fkLanguageBranchID = (SELECT tblContent.fkMasterLanguageBranchID FROM tblContent
			WHERE tblContent.pkID=L.fkContentID)
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
		ExternalFolderID AS PageFolderID,
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
		ContentLink AS PageLinkID,
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
		(tblContentProperty.fkLanguageBranchID = @LanguageBranchID
	OR
		tblContentProperty.fkLanguageBranchID = tblContent.fkMasterLanguageBranchID)
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
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7008
GO
PRINT N'Creating [dbo].[netProjectDelete]...';


GO
CREATE PROCEDURE [dbo].[netProjectDelete]
	@ID	INT
AS
	SET NOCOUNT ON
		DELETE FROM tblProjectItem WHERE fkProjectID = @ID
		DELETE FROM tblProjectMember WHERE fkProjectID = @ID 
		DELETE FROM tblProject WHERE pkID = @ID 
	RETURN @@ROWCOUNT
GO
PRINT N'Creating [dbo].[netProjectGet]...';


GO
CREATE PROCEDURE [dbo].[netProjectGet]
	@ID int
AS
BEGIN
	SELECT pkID, IsPublic, Name, Created, CreatedBy, [Status], PublishingTrackingToken
	FROM tblProject
	WHERE tblProject.pkID = @ID

	SELECT pkID, Name, Type
	FROM tblProjectMember
	WHERE tblProjectMember.fkProjectID = @ID
	ORDER BY Name ASC
END
GO
PRINT N'Creating [dbo].[netProjectItemDelete]...';


GO
CREATE PROCEDURE [dbo].[netProjectItemDelete]
	@ProjectItemIDs dbo.IDTable READONLY
AS
BEGIN
	SET NOCOUNT ON

	MERGE tblProjectItem AS Target
	USING @ProjectItemIDs AS Source
    ON (Target.pkID = Source.ID)
    WHEN MATCHED THEN 
		DELETE
	OUTPUT DELETED.pkID, DELETED.fkProjectID, DELETED.ContentLinkID, DELETED.ContentLinkWorkID, DELETED.ContentLinkProvider, DELETED.Language, DELETED.Category;
END
GO
PRINT N'Creating [dbo].[netProjectItemGet]...';


GO
CREATE PROCEDURE [dbo].[netProjectItemGet]
	@ProjectID INT,
	@StartIndex INT = 0,
	@MaxRows INT,
	@Category VARCHAR(2555) = NULL,
	@Language VARCHAR(17) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	WITH PageCTE AS
    (SELECT pkID,fkProjectID, ContentLinkID, ContentLinkWorkID, ContentLinkProvider, Language, Category,
     ROW_NUMBER() OVER(ORDER By pkID) AS intRow
     FROM tblProjectItem
	 WHERE	(@Category IS NULL OR tblProjectItem.Category = @Category) AND 
			(@Language IS NULL OR tblProjectItem.Language = @Language) AND
			(tblProjectItem.fkProjectID = @ProjectID))
	 
	--ProjectItems
	SELECT
		  pkID, fkProjectID, ContentLinkID, ContentLinkWorkID, ContentLinkProvider, Language, Category, (SELECT COUNT(*) FROM PageCTE) AS 'TotalRows'
	FROM
		PageCTE
	WHERE intRow BETWEEN (@StartIndex +1) AND (@MaxRows + @StartIndex)
END
GO
PRINT N'Creating [dbo].[netProjectItemGetByReferences]...';


GO
CREATE PROCEDURE [dbo].[netProjectItemGetByReferences]
	@References dbo.ContentReferenceTable READONLY
AS
BEGIN
	SET NOCOUNT ON;
	--ProjectItems
	SELECT
		tblProjectItem.pkID, tblProjectItem.fkProjectID, tblProjectItem.ContentLinkID, tblProjectItem.ContentLinkWorkID, tblProjectItem.ContentLinkProvider, tblProjectItem.Language, tblProjectItem.Category
	FROM
		tblProjectItem
	INNER JOIN @References AS Refs ON ((Refs.ID = tblProjectItem.ContentLinkID) AND 
											 (Refs.WorkID = 0 OR  Refs.WorkID = tblProjectItem.ContentLinkWorkID) AND 
											 (Refs.Provider = tblProjectItem.ContentLinkProvider)) 

END
GO
PRINT N'Creating [dbo].[netProjectItemSave]...';


GO
CREATE PROCEDURE [dbo].[netProjectItemSave]
	@ProjectItems dbo.ProjectItemTable READONLY
AS
BEGIN
	SET NOCOUNT ON

	MERGE tblProjectItem AS Target
	USING @ProjectItems AS Source
    ON (Target.pkID = Source.ID)
    WHEN MATCHED THEN
        UPDATE SET 
			Target.fkProjectID = Source.ProjectID,
			Target.ContentLinkID = Source.ContentLinkID,
			Target.ContentLinkWorkID = Source.ContentLinkWorkID,
			Target.ContentLinkProvider = Source.ContentLinkProvider,
			Target.Language = Source.Language,
			Target.Category = Source.Category
	WHEN NOT MATCHED BY Target THEN
		INSERT (fkProjectID, ContentLinkID, ContentLinkWorkID, ContentLinkProvider, Language, Category)
		VALUES (Source.ProjectID, Source.ContentLinkID, Source.ContentLinkWorkID, Source.ContentLinkProvider, Source.Language, Source.Category)
	OUTPUT INSERTED.pkID, INSERTED.fkProjectID, INSERTED.ContentLinkID, INSERTED.ContentLinkWorkID, INSERTED.ContentLinkProvider, INSERTED.Language, INSERTED.Category;

END
GO
PRINT N'Creating [dbo].[netProjectList]...';


GO
CREATE PROCEDURE [dbo].[netProjectList]
	@StartIndex INT = 0,
	@MaxRows INT,
	@Status INT = -1
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @projectIDs TABLE(projectID INT NOT NULL, TotalRows INT NOT NULL);

	WITH PageCTE AS
    (SELECT pkID, [Status],
     ROW_NUMBER() OVER(ORDER BY Name ASC, pkID ASC) AS intRow
     FROM tblProject
	 WHERE @Status  = -1 OR @Status = [Status])

	INSERT INTO  @projectIDs 
		SELECT PageCTE.pkID, (SELECT COUNT(*) FROM PageCTE) AS 'TotalRows' 
		FROM PageCTE 
		WHERE intRow BETWEEN (@StartIndex +1) AND (@MaxRows + @StartIndex)

	--Projects
	SELECT 
		pkID, Name, IsPublic, CreatedBy, Created, [Status], PublishingTrackingToken
	FROM 
		tblProject 
	INNER JOIN @projectIDs AS projects ON projects.projectID = tblProject.pkID


	--ProjectMembers
	SELECT 
		pkID, projectID, Name, Type
	FROM 
		tblProjectMember 
	INNER JOIN @projectIDs AS projects ON projects.projectID = tblProjectMember.fkProjectID
	ORDER BY projectID, Name

	RETURN COALESCE((SELECT TOP 1 TotalRows FROM @projectIDs), 0)

END
GO
PRINT N'Creating [dbo].[netProjectSave]...';


GO

CREATE PROCEDURE [dbo].[netProjectSave]
	@ID INT,
	@Name	nvarchar(255),
	@IsPublic BIT,
	@Created	datetime,
	@CreatedBy	nvarchar(255),
	@Status INT,
	@PublishingTrackingToken nvarchar(255),
	@Members dbo.ProjectMemberTable READONLY
AS
BEGIN
	SET NOCOUNT ON

	IF @ID=0
	BEGIN
		INSERT INTO tblProject(Name, IsPublic, Created, CreatedBy, [Status], PublishingTrackingToken) VALUES(@Name, @IsPublic, @Created, @CreatedBy, @Status, @PublishingTrackingToken)
		SET @ID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE tblProject SET Name=@Name, IsPublic=@IsPublic, [Status] = @Status, PublishingTrackingToken = @PublishingTrackingToken  WHERE pkID=@ID
	END

	MERGE tblProjectMember AS Target
    USING @Members AS Source
    ON (Target.pkID = Source.ID AND Target.fkProjectID=@ID)
    WHEN MATCHED THEN 
        UPDATE SET Name = Source.Name, Type = Source.Type
	WHEN NOT MATCHED BY Source AND Target.fkProjectID = @ID THEN
		DELETE
	WHEN NOT MATCHED BY Target THEN
		INSERT (fkProjectID, Name, Type)
		VALUES (@ID, Source.Name, Source.Type);


	SELECT pkID, Name, Type
	FROM tblProjectMember
	WHERE tblProjectMember.fkProjectID = @ID
	ORDER BY Name ASC

	RETURN @ID
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
			ExternalFolderID AS PageFolderID,
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
			ExternalFolderID AS PageFolderID,
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
		PageLink AS PageLinkID,
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
PRINT N'Altering [dbo].[editContentVersionList]...';


GO
ALTER PROCEDURE dbo.editContentVersionList
(
	@ContentID INT
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @ParentID		INT
	DECLARE @NewWorkContentID	INT
	

	/* Make sure we correct versions for page */
	EXEC netContentEnsureVersions @ContentID=@ContentID	

	/* Get info about all page versions */
	SELECT 
		W.pkID, 
		W.Name,
		W.LinkType,
		W.LinkURL,
		W.Saved, 
		W.CommonDraft,
		W.ChangedByName AS UserNameSaved,
		W.NewStatusByName As UserNameChanged,
		PT.ContentType as ContentType,
		W.Status as  WorkStatus,
		W.RejectComment,
		W.fkMasterVersionID,
		RTRIM(tblLanguageBranch.LanguageID) AS LanguageBranch,
		CASE WHEN tblContent.fkMasterLanguageBranchID=P.fkLanguageBranchID THEN 1 ELSE 0 END AS IsMasterLanguageBranch,
		W.DelayPublishUntil
	FROM
		tblContentLanguage AS P
	INNER JOIN
		tblContent
	ON
		tblContent.pkID=P.fkContentID
	LEFT JOIN
		tblWorkContent AS W
	ON
		W.fkContentID=P.fkContentID
	LEFT JOIN
		tblContentType AS PT
	ON
		tblContent.fkContentTypeID = PT.pkID
	LEFT JOIN
		tblLanguageBranch
	ON
		tblLanguageBranch.pkID=W.fkLanguageBranchID
	WHERE
		W.fkContentID=@ContentID AND W.fkLanguageBranchID=P.fkLanguageBranchID
	ORDER BY
		W.pkID
	RETURN 0
END
GO
PRINT N'Altering [dbo].[editPublishContentVersion]...';


GO
ALTER PROCEDURE dbo.editPublishContentVersion
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
			StartPublish	= COALESCE(W.StartPublish, tblContentLanguage.StartPublish, DATEADD(s, -30, @PublishedDate)),
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
		DelayPublishUntil = NULL
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


-- BEGIN - Manually created update
GO
PRINT N'Initializing field [dbo].[tblWorkContent].[DelayPublishUntil]...';

GO
UPDATE tblWorkContent SET DelayPublishUntil = StartPublish WHERE Status = 6

GO
PRINT N'Restoring actual publish date in field [dbo].[tblWorkContent].[StartPublish]...';

GO
UPDATE tblWorkContent SET StartPublish = L.StartPublish 
	FROM tblContentLanguage AS L INNER JOIN tblWorkContent AS W 
	ON L.fkContentID = W.fkContentID AND L.fkLanguageBranchID = W.fkLanguageBranchID
	WHERE W.Status = 6

-- END - Manually created update
PRINT N'Creating [dbo].[netProjectItemGetSingle]...';

GO
CREATE PROCEDURE [dbo].[netProjectItemGetSingle]
	@ID INT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		  pkID, fkProjectID, ContentLinkID, ContentLinkWorkID, ContentLinkProvider, [Language], Category
	FROM
		tblProjectItem
	WHERE pkID = @ID
END
GO

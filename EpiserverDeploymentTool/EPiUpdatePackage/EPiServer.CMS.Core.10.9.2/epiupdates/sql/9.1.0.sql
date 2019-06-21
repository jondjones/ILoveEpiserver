--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7025)
				select 0, 'Already correct database version'
            else if (@ver = 7024)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO
PRINT N'Altering [dbo].[tblBigTableStoreConfig]...';


GO
ALTER TABLE [dbo].[tblBigTableStoreConfig]
    ADD [DateTimeKind] INT DEFAULT 0 NOT NULL;

GO
PRINT N'Dropping DF__tblContentLanguage__Changed...';


GO
ALTER TABLE [dbo].[tblContentLanguage] DROP CONSTRAINT [DF__tblContentLanguage__Changed];


GO
PRINT N'Dropping DF__tblContentLanguage__Created...';


GO
ALTER TABLE [dbo].[tblContentLanguage] DROP CONSTRAINT [DF__tblContentLanguage__Created];


GO
PRINT N'Dropping DF__tblContentLanguage__Saved...';


GO
ALTER TABLE [dbo].[tblContentLanguage] DROP CONSTRAINT [DF__tblContentLanguage__Saved];


GO
PRINT N'Dropping DF_tblContentType_Registered...';


GO
ALTER TABLE [dbo].[tblContentType] DROP CONSTRAINT [DF_tblContentType_Registered];


GO
PRINT N'Dropping DF_tblPlugIn_Accessed...';


GO
ALTER TABLE [dbo].[tblPlugIn] DROP CONSTRAINT [DF_tblPlugIn_Accessed];


GO
PRINT N'Dropping DF_tblPlugIn_Created...';


GO
ALTER TABLE [dbo].[tblPlugIn] DROP CONSTRAINT [DF_tblPlugIn_Created];


GO
PRINT N'Dropping DF_tblTask_Changed...';


GO
ALTER TABLE [dbo].[tblTask] DROP CONSTRAINT [DF_tblTask_Changed];


GO
PRINT N'Dropping DF_tblTask_Created...';


GO
ALTER TABLE [dbo].[tblTask] DROP CONSTRAINT [DF_tblTask_Created];


GO
PRINT N'Dropping DF__tblWorkPa__Creat__49AEE81E...';


GO
ALTER TABLE [dbo].[tblWorkContent] DROP CONSTRAINT [DF__tblWorkPa__Creat__49AEE81E];


GO
PRINT N'Dropping DF__tblWorkPa__Saved__4AA30C57...';


GO
ALTER TABLE [dbo].[tblWorkContent] DROP CONSTRAINT [DF__tblWorkPa__Saved__4AA30C57];


GO
PRINT N'Altering [dbo].[editCreateContentVersion]...';


GO
ALTER PROCEDURE [dbo].[editCreateContentVersion]
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
			fkLanguageBranchID)
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
			@LangBranchID
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
				fkLanguageBranchID)
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
				@LangBranchID
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
PRINT N'Altering [dbo].[netContentCreateLanguage]...';


GO
ALTER PROCEDURE [dbo].[netContentCreateLanguage]
(
	@ContentID			INT,
	@WorkContentID		INT,
	@UserName NVARCHAR(255),
	@MaxVersions	INT = NULL,
	@SavedDate		DATETIME,
	@LanguageBranch	NCHAR(17)
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @LangBranchID		INT
	DECLARE @NewVersionID		INT
	
	SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID=@LanguageBranch
	IF @LangBranchID IS NULL
	BEGIN
		RAISERROR (N'netContentCreateLanguage: LanguageBranchID is null, possibly empty table tblLanguageBranch', 16, 1, @WorkContentID)
		RETURN 0
	END

	IF NOT EXISTS( SELECT * FROM tblContentLanguage WHERE fkContentID=@ContentID )
		UPDATE tblContent SET fkMasterLanguageBranchID=@LangBranchID WHERE pkID=@ContentID
	
	INSERT INTO tblContentLanguage(fkContentID, CreatorName, ChangedByName, Status, fkLanguageBranchID, Created, Changed, Saved)
	SELECT @ContentID, @UserName, @UserName, 2, @LangBranchID, @SavedDate, @SavedDate, @SavedDate 
	FROM tblContent
	INNER JOIN tblContentType ON tblContentType.pkID=tblContent.fkContentTypeID
	WHERE tblContent.pkID=@ContentID
			
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
		CommonDraft)
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
					ELSE 1												/* EPnLinkShortcut */
				END)
			ELSE
				(CASE 
					WHEN tblContentLanguage.LinkURL=N'#' THEN 3			/* EPnLinkInactive */
					ELSE 2												/* EPnLinkExternal */
				END)
		END AS LinkType ,
		tblContentLanguage.Created,
		@SavedDate,
		tblContentLanguage.StartPublish,
		tblContentLanguage.StopPublish,
		tblContent.ChildOrderRule,
		tblContent.PeerOrder,
		@LangBranchID,
		0
	FROM tblContentLanguage
	INNER JOIN tblContent ON tblContent.pkID=tblContentLanguage.fkContentID
	WHERE 
		tblContentLanguage.fkContentID=@ContentID AND tblContentLanguage.fkLanguageBranchID=@LangBranchID
		
	SET @NewVersionID = SCOPE_IDENTITY()	
	
	UPDATE tblContentLanguage SET Version = @NewVersionID
	WHERE fkContentID = @ContentID AND fkLanguageBranchID = @LangBranchID
		
	RETURN  @NewVersionID 

END
GO
PRINT N'Altering [dbo].[netContentMove]...';


GO
ALTER PROCEDURE [dbo].[netContentMove]
(
	@ContentID				INT,
	@DestinationContentID	INT,
	@WastebasketID		INT,
	@Archive			INT,
	@DeletedBy			VARCHAR(255) = NULL,
	@DeletedDate		DATETIME = NULL, 
	@Saved				DATETIME
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @TmpParentID		INT
	DECLARE @SourceParentID		INT
	DECLARE @TmpNestingLevel	INT
	DECLARE @Delete				BIT
	DECLARE @IsDestinationLeafNode BIT
	DECLARE @SourcePath VARCHAR(7000)
	DECLARE @TargetPath VARCHAR(7000)
 
	/* Protect from moving Content under itself */
	IF (EXISTS (SELECT NestingLevel FROM tblTree WHERE fkParentID=@ContentID AND fkChildID=@DestinationContentID) OR @DestinationContentID=@ContentID)
		RETURN -1
    
    SELECT @SourcePath=ContentPath + CONVERT(VARCHAR, @ContentID) + '.' FROM tblContent WHERE pkID=@ContentID
    SELECT @TargetPath=ContentPath + CONVERT(VARCHAR, @DestinationContentID) + '.', @IsDestinationLeafNode=IsLeafNode FROM tblContent WHERE pkID=@DestinationContentID
    
	/* Switch parent to archive Content, disable stop publish and update Saved */
	UPDATE tblContent SET
		@SourceParentID		= fkParentID,
		fkParentID			= @DestinationContentID,
		ContentPath            = @TargetPath
	WHERE pkID=@ContentID

	IF @IsDestinationLeafNode = 1
		UPDATE tblContent SET IsLeafNode = 0 WHERE pkID=@DestinationContentID
	IF NOT EXISTS(SELECT * FROM tblContent WHERE fkParentID=@SourceParentID)
		UPDATE tblContent SET IsLeafNode = 1 WHERE pkID=@SourceParentID

    IF (@Archive = 1)
	BEGIN
		UPDATE tblContentLanguage SET
			StopPublish			= NULL,
			Saved				= @Saved
		WHERE fkContentID=@ContentID

		UPDATE tblWorkContent SET
			StopPublish			= NULL
		WHERE fkContentID = @ContentID
	END
	 
	/* Remove all references to this Content and its childs, but preserve the 
		information below itself */
	DELETE FROM 
		tblTree 
	WHERE 
		fkChildID IN (SELECT fkChildID FROM tblTree WHERE fkParentID=@ContentID UNION SELECT @ContentID) AND
		fkParentID NOT IN (SELECT fkChildID FROM tblTree WHERE fkParentID=@ContentID UNION SELECT @ContentID)
 
	/* Insert information about new Contents for all Contents where the destination is a child */
	DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT fkParentID, NestingLevel FROM tblTree WHERE fkChildID=@DestinationContentID
	OPEN cur
	FETCH NEXT FROM cur INTO @TmpParentID, @TmpNestingLevel
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		INSERT INTO tblTree
			(fkParentID,
			fkChildID,
			NestingLevel)
		SELECT
			@TmpParentID,
			fkChildID,
			@TmpNestingLevel + NestingLevel + 1
		FROM
			tblTree
		WHERE
			fkParentID=@ContentID
		UNION ALL
		SELECT
			@TmpParentID,
			@ContentID,
			@TmpNestingLevel + 1
	 
		FETCH NEXT FROM cur INTO @TmpParentID, @TmpNestingLevel
	END
	CLOSE cur
	DEALLOCATE cur

	/* Insert information about new Contents for destination */
	INSERT INTO tblTree
		(fkParentID,
		fkChildID,
		NestingLevel)
	SELECT
		@DestinationContentID,
		fkChildID,
		NestingLevel+1
	FROM
		tblTree
	WHERE
		fkParentID=@ContentID
	UNION
	SELECT
		@DestinationContentID,
		@ContentID,
		1
  
    /* Determine if destination is somewhere under wastebasket */
    SET @Delete=0
    IF (EXISTS (SELECT NestingLevel FROM tblTree WHERE fkParentID=@WastebasketID AND fkChildID=@ContentID))
        SET @Delete=1
    
    /* Update deleted bit of Contents */
    UPDATE tblContent  SET 
		Deleted=@Delete,
		DeletedBy = @DeletedBy,
		DeletedDate = @DeletedDate
    WHERE pkID IN (SELECT fkChildID FROM tblTree WHERE fkParentID=@ContentID) OR pkID=@ContentID
	/* Update saved date for Content */
	IF(@Delete > 0)
	BEGIN
		UPDATE tblContentLanguage  SET 
				Saved = @Saved
   		WHERE fkContentID IN (SELECT fkChildID FROM tblTree WHERE fkParentID=@ContentID) OR fkContentID=@ContentID
	END
 
    /* Create materialized path to moved Contents */
    UPDATE tblContent
    SET ContentPath=@TargetPath + CONVERT(VARCHAR, @ContentID) + '.' + RIGHT(ContentPath, LEN(ContentPath) - LEN(@SourcePath))
    WHERE pkID IN (SELECT fkChildID FROM tblTree WHERE fkParentID = @ContentID) /* Where Content is below source */    
    
	RETURN 0
END
GO
PRINT N'Altering [dbo].[netContentTypeSave]...';


GO
ALTER PROCEDURE [dbo].[netContentTypeSave]
(
	@ContentTypeID			INT					OUTPUT,
	@ContentTypeGUID		UNIQUEIDENTIFIER	OUTPUT,
	@Name				NVARCHAR(50),
	@DisplayName		NVARCHAR(50)    = NULL,
	@Description		NVARCHAR(255)	= NULL,
	@DefaultWebFormTemplate	NVARCHAR(1024)   = NULL,
	@DefaultMvcController NVARCHAR(1024)   = NULL,
	@DefaultMvcPartialView			NVARCHAR(255)   = NULL,
	@Filename			NVARCHAR(255)   = NULL,
	@Available			BIT				= NULL,
	@SortOrder			INT				= NULL,
	@ModelType			NVARCHAR(1024)	= NULL,
	
	@DefaultID			INT				= NULL,
	@DefaultName 		NVARCHAR(100)	= NULL,
	@StartPublishOffset	INT				= NULL,
	@StopPublishOffset	INT				= NULL,
	@VisibleInMenu		BIT				= NULL,
	@PeerOrder 			INT				= NULL,
	@ChildOrderRule 	INT				= NULL,
	@ArchiveContentID 		INT				= NULL,
	@FrameID 			INT				= NULL,
	@ACL				NVARCHAR(MAX)	= NULL,	
	@ContentType		INT				= 0,
	@Created			DATETIME
)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IdString NVARCHAR(255)
	
	IF @ContentTypeID <= 0
	BEGIN
		SET @ContentTypeID = ISNULL((SELECT pkID FROM tblContentType where Name = @Name), @ContentTypeID)
	END

	IF (@ContentTypeID <= 0)
	BEGIN
		SELECT TOP 1 @IdString=IdString FROM tblContentType
		INSERT INTO tblContentType
			(Name,
			DisplayName,
			DefaultMvcController,
			DefaultWebFormTemplate,
			DefaultMvcPartialView,
			Description,
			Available,
			SortOrder,
			ModelType,
			Filename,
			IdString,
			ContentTypeGUID,
			ACL,
			ContentType,
			Created)
		VALUES
			(@Name,
			@DisplayName,
			@DefaultMvcController,
			@DefaultWebFormTemplate,
			@DefaultMvcPartialView,
			@Description,
			@Available,
			@SortOrder,
			@ModelType,
			@Filename,
			@IdString,
			CASE WHEN @ContentTypeGUID IS NULL THEN NewId() ELSE @ContentTypeGUID END,
			@ACL,
			@ContentType,
			@Created)

		SET @ContentTypeID= SCOPE_IDENTITY() 
		
	END
	ELSE
	BEGIN
		BEGIN
			UPDATE tblContentType
			SET
				Name=@Name,
				DisplayName=@DisplayName,
				Description=@Description,
				DefaultWebFormTemplate=@DefaultWebFormTemplate,
				DefaultMvcController=@DefaultMvcController,
				DefaultMvcPartialView=@DefaultMvcPartialView,
				Available=@Available,
				SortOrder=@SortOrder,
				ModelType = @ModelType,
				Filename = @Filename,
				ACL=@ACL,
				ContentType = @ContentType
			WHERE
				pkID=@ContentTypeID
		END
	END

	SELECT @ContentTypeGUID=ContentTypeGUID FROM tblContentType WHERE pkID=@ContentTypeID
	
	IF (@DefaultID IS NULL)
	BEGIN
		DELETE FROM tblContentTypeDefault WHERE fkContentTypeID=@ContentTypeID
		RETURN 0
	END
	
	IF (EXISTS (SELECT pkID FROM tblContentTypeDefault WHERE fkContentTypeID=@ContentTypeID))
	BEGIN
		UPDATE tblContentTypeDefault SET
			Name 				= @DefaultName,
			StartPublishOffset 	= @StartPublishOffset,
			StopPublishOffset 	= @StopPublishOffset,
			VisibleInMenu 		= @VisibleInMenu,
			PeerOrder 			= @PeerOrder,
			ChildOrderRule 		= @ChildOrderRule,
			fkArchiveContentID 	= @ArchiveContentID,
			fkFrameID 			= @FrameID
		WHERE fkContentTypeID=@ContentTypeID
	END
	ELSE
	BEGIN
		INSERT INTO tblContentTypeDefault 
			(fkContentTypeID,
			Name,
			StartPublishOffset,
			StopPublishOffset,
			VisibleInMenu,
			PeerOrder,
			ChildOrderRule,
			fkArchiveContentID,
			fkFrameID)
		VALUES
			(@ContentTypeID,
			@DefaultName,
			@StartPublishOffset,
			@StopPublishOffset,
			@VisibleInMenu,
			@PeerOrder,
			@ChildOrderRule,
			@ArchiveContentID,
			@FrameID)
	END
		
	RETURN 0
END
GO
PRINT N'Altering [dbo].[netPagesChangedAfter]...';


GO
ALTER PROCEDURE dbo.netPagesChangedAfter
( 
	@RootID INT,
	@ChangedAfter DATETIME,
	@MaxHits INT,
	@StopPublish DATETIME
)
AS
BEGIN
	SET NOCOUNT ON
    SET @MaxHits = @MaxHits + 1 -- Return one more to determine if there are more pages to fetch (gets MaxHits + 1)
    SET ROWCOUNT @MaxHits
    
	SELECT 
	    tblPageLanguage.fkPageID AS PageID,
		RTRIM(tblLanguageBranch.LanguageID) AS LanguageID
	FROM
		tblPageLanguage
	INNER JOIN
		tblTree
	ON
		tblPageLanguage.fkPageID = tblTree.fkChildID AND (tblTree.fkParentID = @RootID OR (tblTree.fkChildID = @RootID AND tblTree.NestingLevel = 1))
	INNER JOIN
		tblLanguageBranch
	ON
		tblPageLanguage.fkLanguageBranchID = tblLanguageBranch.pkID
	WHERE
		(tblPageLanguage.Changed > @ChangedAfter OR tblPageLanguage.StartPublish > @ChangedAfter) AND
		(tblPageLanguage.StopPublish is NULL OR tblPageLanguage.StopPublish > @StopPublish) AND
		tblPageLanguage.PendingPublish=0
	ORDER BY
		tblTree.NestingLevel,
		tblPageLanguage.fkPageID,
		tblPageLanguage.Changed DESC
		
	SET ROWCOUNT 0
END
GO
PRINT N'Altering [dbo].[netPlugInSave]...';


GO
ALTER PROCEDURE dbo.netPlugInSave
@PlugInID 		INT,
@Enabled 		BIT,
@Saved		DATETIME
AS
BEGIN

	UPDATE tblPlugIn SET
		Enabled 	= @Enabled,
		Saved		= @Saved
	WHERE pkID = @PlugInID
END
GO
PRINT N'Altering [dbo].[netPlugInSaveSettings]...';


GO

ALTER PROCEDURE dbo.netPlugInSaveSettings
@PlugInID 		INT,
@Settings 		NVARCHAR(MAX),
@Saved			DATETIME

AS
BEGIN

	UPDATE tblPlugIn SET
		Settings 	= @Settings,
		Saved		= @Saved	
	WHERE pkID = @PlugInID
END
GO
PRINT N'Altering [dbo].[netPlugInSynchronize]...';


GO
ALTER PROCEDURE dbo.netPlugInSynchronize
(
	@AssemblyName NVARCHAR(255),
	@TypeName NVARCHAR(255),
	@DefaultEnabled Bit,
	@CurrentDate DATETIME
)
AS
BEGIN

	SET NOCOUNT ON
	DECLARE @id INT

	SELECT @id = pkID FROM tblPlugIn WHERE AssemblyName=@AssemblyName AND TypeName=@TypeName
	IF @id IS NULL
	BEGIN
		INSERT INTO tblPlugIn(AssemblyName,TypeName,Enabled, Created, Saved) VALUES(@AssemblyName,@TypeName,@DefaultEnabled, @CurrentDate, @CurrentDate)
		SET @id =  SCOPE_IDENTITY() 
	END
	SELECT pkID, TypeName, AssemblyName, Saved, Created, Enabled FROM tblPlugIn WHERE pkID = @id

END
GO
PRINT N'Altering [dbo].[netQuickSearchByExternalUrl]...';


GO
ALTER PROCEDURE dbo.netQuickSearchByExternalUrl
(
	@Url	NVARCHAR(255),
	@CurrentTime	DATETIME
)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @LoweredUrl NVARCHAR(255)
	
	SET @LoweredUrl = Lower(@Url)

	/*
		Performance notes: The subquery "Pages" must not have any more predicates or return the values used in the outer WHERE-clause, otherwise
		SQL Server falls back to a costly index scan. The performance hints LOOP on the joins are also required for the same reason, the resultset
		from "Pages" is so small that a loop join is superior in performance to index scan/hash match, a factor 1000x.
	*/
	
	SELECT 
		tblPageLanguage.fkPageID,
		tblLanguageBranch.LanguageID as LanguageBranch
	FROM 
		(
			SELECT fkPageID,fkLanguageBranchID
			FROM tblPageLanguage
			WHERE tblPageLanguage.ExternalURL=@LoweredUrl
		) AS Pages
	INNER LOOP JOIN 
		tblPage ON tblPage.pkID = Pages.fkPageID
	INNER LOOP JOIN
		tblPageLanguage ON tblPageLanguage.fkPageID=Pages.fkPageID AND tblPageLanguage.fkLanguageBranchID=Pages.fkLanguageBranchID
	INNER LOOP JOIN
		tblLanguageBranch ON tblLanguageBranch.pkID = Pages.fkLanguageBranchID
	WHERE 
		tblPage.Deleted=0 AND 
		tblPageLanguage.[Status]=4 AND
		tblPageLanguage.StartPublish <= @CurrentTime AND
		(tblPageLanguage.StopPublish IS NULL OR tblPageLanguage.StopPublish >= @CurrentTime)
	ORDER BY
		tblPageLanguage.Changed DESC
END
GO
PRINT N'Altering [dbo].[netSchedulerExecute]...';


GO
ALTER PROCEDURE dbo.netSchedulerExecute
(
	@pkID     uniqueidentifier,
	@nextExec datetime,
	@utcnow datetime,
	@pingSeconds int
)
as
begin

	set nocount on
	
	
	/**
	 * is the scheduled nextExec still valid? 
	 * (that is, no one else has already begun executing it?)
	 */
	if exists( select * from tblScheduledItem with (rowlock,updlock) where pkID = @pkID and NextExec = @nextExec and Enabled = 1 and (IsRunning <> 1 OR (GETUTCDATE() > DATEADD(second, @pingSeconds, LastPing))) )
	begin
	
		/**
		 * ya, calculate and set nextexec for the item 
		 * (or set to null if not recurring)
		 */
		update tblScheduledItem set NextExec =  case when coalesce(Interval,0) > 0 and [DatePart] is not null then 
		
															case [DatePart] when 'ms' then dateadd( ms, Interval, case when dateadd( ms, Interval, NextExec ) < @utcnow then @utcnow else NextExec end )
																			when 'ss' then dateadd( ss, Interval, case when dateadd( ss, Interval, NextExec ) < @utcnow then @utcnow else NextExec end )
																			when 'mi' then dateadd( mi, Interval, case when dateadd( mi, Interval, NextExec ) < @utcnow then @utcnow else NextExec end )
																			when 'hh' then dateadd( hh, Interval, case when dateadd( hh, Interval, NextExec ) < @utcnow then @utcnow else NextExec end )
																			when 'dd' then dateadd( dd, Interval, case when dateadd( dd, Interval, NextExec ) < @utcnow then @utcnow else NextExec end )
																			when 'wk' then dateadd( wk, Interval, case when dateadd( wk, Interval, NextExec ) < @utcnow then @utcnow else NextExec end )
																			when 'mm' then dateadd( mm, Interval, case when dateadd( mm, Interval, NextExec ) < @utcnow then @utcnow else NextExec end )
																			when 'yy' then dateadd( yy, Interval, case when dateadd( yy, Interval, NextExec ) < @utcnow then @utcnow else NextExec end )
																			
															end
													
													 else null
									            end
		from   tblScheduledItem
		
		where  pkID = @pkID
		
		
		/**
		 * now retrieve all detailed data (type, assembly & instance) 
		 * for the job
		 */
		select	tblScheduledItem.MethodName,
				tblScheduledItem.fStatic,
				tblScheduledItem.TypeName,
				tblScheduledItem.AssemblyName,
				tblScheduledItem.InstanceData
		
		from	tblScheduledItem
		
		where	pkID = @pkID
		
	end
	
end
GO
PRINT N'Altering [dbo].[netSchedulerList]...';


GO
ALTER PROCEDURE [dbo].netSchedulerList
AS
BEGIN

	SELECT CONVERT(NVARCHAR(40),pkID) AS pkID,Name,CONVERT(INT,Enabled) AS Enabled,LastExec,LastStatus,LastText,NextExec,[DatePart],Interval,MethodName,CONVERT(INT,fStatic) AS fStatic,TypeName,AssemblyName,InstanceData, IsRunning, CurrentStatusMessage, DateDiff(second, LastPing, GETUTCDATE()) as SecondsAfterLastPing
	FROM tblScheduledItem
	ORDER BY Name ASC

END
GO
PRINT N'Altering [dbo].[netSchedulerLoadJob]...';


GO
ALTER PROCEDURE dbo.netSchedulerLoadJob 
	@pkID UNIQUEIDENTIFIER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    SELECT CONVERT(NVARCHAR(40),pkID) AS pkID,Name,CONVERT(INT,Enabled) AS Enabled,LastExec,LastStatus,LastText,NextExec,[DatePart],Interval,MethodName,CONVERT(INT,fStatic) AS fStatic,TypeName,AssemblyName,InstanceData, IsRunning, CurrentStatusMessage, DateDiff(second, LastPing, GETUTCDATE()) as SecondsAfterLastPing
	FROM tblScheduledItem
	WHERE pkID = @pkID
END
GO
PRINT N'Altering [dbo].[netSchedulerSetRunningState]...';


GO
ALTER PROCEDURE dbo.netSchedulerSetRunningState
	@pkID UNIQUEIDENTIFIER,
	@IsRunning bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE tblScheduledItem SET IsRunning = @IsRunning, LastPing = GETUTCDATE(), CurrentStatusMessage = NULL WHERE pkID = @pkID
END
GO
PRINT N'Altering [dbo].[netTaskSave]...';


GO
ALTER PROCEDURE dbo.netTaskSave
(
    @TaskID INT OUTPUT,
    @Subject NVARCHAR(255),
    @Description NVARCHAR(2000) = NULL,
    @DueDate DATETIME = NULL,
    @OwnerName NVARCHAR(255),
    @AssignedToName NVARCHAR(255),
    @AssignedIsRole BIT,
    @Status INT,
    @PlugInID INT = NULL,
    @Activity NVARCHAR(MAX) = NULL,
    @State NVARCHAR(MAX) = NULL,
    @WorkflowInstanceId NVARCHAR(36) = NULL,
    @EventActivityName NVARCHAR(255) = NULL,
	@CurrentDate DATETIME
)
AS
BEGIN
    -- Create new task
	IF @TaskID = 0
	BEGIN
		INSERT INTO tblTask
		    (Subject,
		    Description,
		    DueDate,
		    OwnerName,
		    AssignedToName,
		    AssignedIsRole,
		    Status,
		    Activity,
		    fkPlugInID,
		    State,
		    WorkflowInstanceId,
		    EventActivityName,
			Created,
			Changed) 
		VALUES
		    (@Subject,
		    @Description,
		    @DueDate,
		    @OwnerName,
		    @AssignedToName,
		    @AssignedIsRole,
		    @Status,
		    @Activity,
		    @PlugInID,
		    @State,
		    @WorkflowInstanceId,
			@EventActivityName,
			@CurrentDate,
			@CurrentDate)
		SET @TaskID= SCOPE_IDENTITY() 
		
		RETURN
	END

    -- Update existing task
	UPDATE tblTask SET
		Subject = @Subject,
		Description = @Description,
		DueDate = @DueDate,
		OwnerName = @OwnerName,
		AssignedToName = @AssignedToName,
		AssignedIsRole = @AssignedIsRole,
		Status = @Status,
		Activity = CASE WHEN @Activity IS NULL THEN Activity ELSE @Activity END,
		State = @State,
		fkPlugInID = @PlugInID,
		WorkflowInstanceId = @WorkflowInstanceId,
		EventActivityName = @EventActivityName,
		Changed = @CurrentDate
	WHERE pkID = @TaskID
END
GO

PRINT N'Refreshing [dbo].[netContentEnsureVersions]...';

GO

EXECUTE sp_refreshsqlmodule N'[dbo].[netContentEnsureVersions]';

GO

PRINT N'Refreshing [dbo].[editContentVersionList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editContentVersionList]';

GO
PRINT N'Altering [dbo].[sp_GetDateTimeKind]...';

GO
CREATE PROCEDURE [dbo].[sp_GetDateTimeKind]
AS
	-- 0 === Unspecified  
	-- 1 === Local time 
	-- 2 === UTC time 
	RETURN 0

GO

PRINT N'Creating [dbo].[DateTimeConversion_DateTimeOffset]...';


GO
CREATE TYPE [dbo].[DateTimeConversion_DateTimeOffset] AS TABLE (
    [IntervalStart] DATETIME   NOT NULL,
    [IntervalEnd]   DATETIME   NOT NULL,
    [Offset]        FLOAT (53) NOT NULL);


GO
PRINT N'Creating [dbo].[DateTimeConversion_GetFieldNames]...';


GO
CREATE PROCEDURE [dbo].[DateTimeConversion_GetFieldNames]
AS 
BEGIN 
	SELECT '** TABLENAME **','** DATETIME COLUMNNAME (OPTIONAL) **', '** STORENAME (OPTIONAL) **'

	-- TABLES
	UNION SELECT 'tblContent', NULL, NULL
	UNION SELECT 'tblContentLanguage', NULL, NULL
	UNION SELECT 'tblContentProperty', NULL, NULL
	UNION SELECT 'tblContentSoftlink', NULL, NULL
	UNION SELECT 'tblContentType', NULL, NULL
	UNION SELECT 'tblPlugIn', NULL, NULL
	UNION SELECT 'tblProject', NULL, NULL
	UNION SELECT 'tblPropertyDefinitionDefault', 'Date', NULL
	UNION SELECT 'tblTask', NULL, NULL
	UNION SELECT 'tblWorkContent', NULL, NULL
	UNION SELECT 'tblWorkContentProperty', NULL, NULL
	UNION SELECT 'tblXFormData', 'DatePosted', NULL

	-- STORES
	UNION SELECT 'tblBigTable', NULL, 'EPiServer.Personalization.VisitorGroups.Criteria.ViewedCategoriesModel'
	UNION SELECT 'tblIndexRequestLog', NULL, 'EPiServer.Search.Data.IndexRequestQueueItem'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiContentRestoreStore'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.ApplicationModules.Security.SiteSecret'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Core.PropertySettings.PropertySettingsContainer'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Core.PropertySettings.PropertySettingsGlobals'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Core.PropertySettings.PropertySettingsWrapper'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Editor.TinyMCE.TinyMCESettings'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Editor.TinyMCE.ToolbarRow'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Licensing.StoredLicense'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.MirroringService.MirroringData'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Shell.Profile.ProfileData'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Shell.Storage.PersonalizedViewSettingsStorage'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Util.BlobCleanupJobState'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Util.ContentAssetsCleanupJobState'
	UNION SELECT 'tblSystemBigTable', NULL, 'GadgetStore'
	UNION SELECT 'tblSystemBigTable', NULL, 'VisitorGroup'
	UNION SELECT 'tblSystemBigTable', NULL, 'VisitorGroupCriterion'
	UNION SELECT 'tblSystemBigTable', NULL, 'XFormFolders'

	-- OBSOLETE STORES
	UNION SELECT 'tblBigTable', NULL, 'EPiServer.Web.HostDefinition'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Web.SiteDefinition'
	UNION SELECT 'tblSystemBigTable', NULL, 'DashboardContainerStore'
	UNION SELECT 'tblSystemBigTable', NULL, 'DashboardLayoutPartStore'
	UNION SELECT 'tblSystemBigTable', NULL, 'DashboardStore'
	UNION SELECT 'tblSystemBigTable', NULL, 'DashboardTabLayoutStore'
	UNION SELECT 'tblSystemBigTable', NULL, 'DashboardTabStore'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Events.Remote.EventSecret'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.Licensing.SiteLicenseData'
	UNION SELECT 'tblSystemBigTable', NULL, 'EPiServer.TaskManager.TaskManagerDynamicData'
	UNION SELECT 'tblBigTable', NULL, 'EPiServer.Core.IndexingInformation'
	UNION SELECT 'tblBigTable', NULL, 'EPiServer.Shell.Search.SearchProviderSetting'
END 
GO
PRINT N'Creating [dbo].[DateTimeConversion_InitDateTimeOffsets]...';


GO
CREATE PROCEDURE [dbo].[DateTimeConversion_InitDateTimeOffsets]
(@DateTimeOffsets [dbo].[DateTimeConversion_DateTimeOffset] READONLY)
AS
BEGIN
	IF OBJECT_ID('[dbo].[tblDateTimeConversion_Offset]', 'U') IS NOT NULL
		DROP TABLE [dbo].[tblDateTimeConversion_Offset]

	CREATE TABLE [dbo].[tblDateTimeConversion_Offset](
		[pkID] [INT] IDENTITY(1,1) NOT NULL,
		[IntervalStart] [DATETIME] NOT NULL, 
		[IntervalEnd] [DATETIME] NOT NULL,
		[Offset] DECIMAL(24,20) NOT NULL,
		CONSTRAINT [PK_tblDateTimeConversion_Offset] PRIMARY KEY  CLUSTERED
		(
			[pkID]
		)
	)
	INSERT INTO [dbo].[tblDateTimeConversion_Offset](IntervalStart, IntervalEnd, Offset)
	SELECT  tbl.IntervalStart,tbl.IntervalEnd,-CAST(tbl.Offset AS DECIMAL(24,20))/24/60 FROM @DateTimeOffsets tbl

	CREATE UNIQUE INDEX IDX_DateTimeConversion_Interval1 ON [dbo].[tblDateTimeConversion_Offset](IntervalStart ASC, IntervalEnd ASC) 
	CREATE UNIQUE INDEX IDX_DateTimeConversion_Interval2 ON [dbo].[tblDateTimeConversion_Offset](IntervalStart DESC, IntervalEnd DESC) 
END
GO
PRINT N'Creating [dbo].[DateTimeConversion_InitTables]...';


GO
CREATE PROCEDURE [dbo].[DateTimeConversion_InitFieldNames]
AS
BEGIN
	IF OBJECT_ID('[dbo].[tblDateTimeConversion_FieldName]', 'U') IS NOT NULL
		DROP TABLE [dbo].[tblDateTimeConversion_FieldName]

	CREATE TABLE [dbo].[tblDateTimeConversion_FieldName](
		[pkID] [int] IDENTITY(1,1) NOT NULL,		
		[TableName] nvarchar(128) NOT NULL,
		[ColName] nvarchar(128) NOT NULL,
		[StoreName] NVARCHAR(375) NULL,
		CONSTRAINT [PK_DateTimeConversion_InitFieldNames] PRIMARY KEY  CLUSTERED
		(
			[pkID]
		)
	)

	DECLARE @FieldNames AS TABLE 
	(
		TableName NVARCHAR(128) NOT NULL,
		ColName NVARCHAR(128) NULL,
		StoreName NVARCHAR(375) NULL
	)

	INSERT INTO @FieldNames
	EXEC DateTimeConversion_GetFieldNames

	INSERT INTO @FieldNames
	SELECT TableName = c.name, ColName = a.name, f.StoreName  from 
		sys.columns a 
		INNER JOIN sys.types t ON a.user_type_id = t.user_type_id AND (t.name = 'datetime' OR t.name = 'datetime2')
		INNER JOIN sys.tables c ON a.object_id = c.object_id 
		INNER JOIN @FieldNames f ON c.object_id = OBJECT_ID(f.TableName)
	WHERE f.ColName IS NULL
	
	DELETE @FieldNames WHERE ColName IS NULL

	DECLARE @DateTimeKind INT
	EXEC @DateTimeKind = sp_GetDateTimeKind
	INSERT INTO [dbo].[tblDateTimeConversion_FieldName](TableName, ColName, StoreName)
	SELECT DISTINCT REPLACE(REPLACE(REPLACE(X.TableName,'[',''),']',''),'dbo.',''), ColName = REPLACE(REPLACE(X.ColName,']',''),'[',''), X.StoreName FROM (
		SELECT f.TableName, f.ColName, StoreName = NULL FROM @FieldNames f WHERE @DateTimeKind = 0 AND f.StoreName IS NULL
		UNION
		SELECT DISTINCT f.TableName, f.ColName, f.StoreName
		FROM sys.columns a 
		INNER JOIN sys.types t ON a.user_type_id = t.user_type_id AND (t.name = 'datetime' OR t.name = 'datetime2')
		INNER JOIN sys.tables c ON a.object_id = c.object_id 
		INNER JOIN tblBigTableStoreConfig i ON c.object_id = OBJECT_ID(i.TableName) AND i.DateTimeKind = 0
		INNER JOIN @FieldNames f ON c.object_id = OBJECT_ID(f.TableName) AND (a.name COLLATE database_default = f.ColName OR '['+a.name COLLATE database_default+']' = f.ColName) AND f.StoreName = i.StoreName
	) X
	INNER JOIN (
		SELECT TableId = c.object_id, ColName = a.name FROM sys.columns a 
		INNER JOIN sys.types t ON a.user_type_id = t.user_type_id AND (t.name = 'datetime' OR t.name = 'datetime2')
		INNER JOIN sys.tables c ON a.object_id = c.object_id
	) Y 
	ON Y.TableId = OBJECT_ID(X.TableName) AND (Y.ColName = X.ColName COLLATE database_default OR '['+Y.ColName +']' = X.ColName COLLATE database_default)
END
GO
PRINT N'Creating [dbo].[DateTimeConversion_MakeTableBlocks]...';


GO
CREATE PROCEDURE [dbo].[DateTimeConversion_MakeTableBlocks]
(
	@TableName NVARCHAR(MAX), 
	@DateTimeColumn NVARCHAR(MAX),
	@StoreName NVARCHAR(MAX), 
	@BlockSize INT, 
	@Print INT)
AS
BEGIN	
	-- Format
	SET @TableName = REPLACE(REPLACE(REPLACE(@TableName,'[',''),']',''),'dbo.','')
	SET @DateTimeColumn = REPLACE(REPLACE(@DateTimeColumn,']',''),'[','')

	-- CHECK tblBigTableReference
	IF (@StoreName IS NOT NULL)
	BEGIN
		DECLARE @BigTableReferenceCount INT
		SELECT @BigTableReferenceCount = COUNT(*) FROM tblBigTableReference r
		JOIN tblBigTableIdentity i ON r.pkId = i.pkId WHERE i.StoreName = @StoreName AND DateTimeValue IS NOT NULL

		IF(@BigTableReferenceCount > 0)
		BEGIN
			DECLARE @BigTableReferenceSql NVARCHAR(MAX) = 
				'UPDATE tbl SET tbl.[DateTimeValue] = CAST([DateTimeValue] AS DATETIME) + dtc.OffSet FROM tblBigTableReference tbl ' +
				'INNER JOIN [dbo].[tblDateTimeConversion_Offset] dtc ON tbl.[DateTimeValue] >= dtc.IntervalStart AND tbl.[DateTimeValue] < dtc.IntervalEnd ' +
				'INNER JOIN [dbo].[tblBigTableIdentity] bti ON bti.StoreName = ''' + @StoreName + ''' AND tbl.pkId = bti.pkId ' +
				'WHERE tbl.[DateTimeValue] IS NOT NULL '
			INSERT INTO [dbo].[tblDateTimeConversion_Block](TableName, ColName, StoreName, [Sql], BlockRank,BlockCount) 
			SELECT TableName = 'tblBigTableReference', ColName = 'DateTimeValue', @StoreName, [Sql] = @BigTableReferenceSql , BlockRank = 0, BlockCount = @BigTableReferenceCount
		END
	END

	-- Get primary keys
	DECLARE @Keys TABLE(Data NVARCHAR(100)) 
	INSERT INTO @Keys
	SELECT i.COLUMN_NAME
	FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE i
	WHERE OBJECTPROPERTY(OBJECT_ID(i.CONSTRAINT_NAME), 'IsPrimaryKey') = 1
	AND i.TABLE_NAME = @TableName

	IF ((SELECT COUNT(*) FROM @Keys) = 0 )
	BEGIN
		INSERT INTO [dbo].[tblDateTimeConversion_Block](TableName, ColName, StoreName, [Sql],Converted,BlockRank,BlockCount) 
		SELECT TableName = @TableName, ColName = @DateTimeColumn, @StoreName, [Sql] = NULL, Converted = 1, BlockRank = -1, BlockCount = 0 
		RETURN		
	END

	-- Get total number of primary keys
	DECLARE @TotalPrimaryKeys INT  
	SELECT @TotalPrimaryKeys = COUNT(*) FROM @Keys

	-- Get number of integer primary keys
	DECLARE @IntegerPrimaryKeys INT  
	SELECT @IntegerPrimaryKeys = COUNT(*)
	FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE i
	JOIN INFORMATION_SCHEMA.COLUMNS c on i.COLUMN_NAME = c.COLUMN_NAME AND i.TABLE_NAME = c.TABLE_NAME
	WHERE OBJECTPROPERTY(OBJECT_ID(i.CONSTRAINT_NAME), 'IsPrimaryKey') = 1 AND c.DATA_TYPE IN ('bigint','int')
	AND i.TABLE_NAME = @TableName

	-- Non integer primary keys handling
	IF (@TotalPrimaryKeys > @IntegerPrimaryKeys)
	BEGIN
		DECLARE @NonIntegerSql NVARCHAR(MAX) = 'UPDATE tbl SET tbl.[' + @DateTimeColumn + '] = CAST('+ @DateTimeColumn +' AS DATETIME) + dtc.OffSet FROM ' + @TableName + ' tbl INNER JOIN [dbo].[tblDateTimeConversion_Offset] dtc ON tbl.[' + @DateTimeColumn + '] >= dtc.IntervalStart AND tbl.[' + @DateTimeColumn + '] < dtc.IntervalEnd WHERE tbl.[' + @DateTimeColumn + '] IS NOT NULL '
		INSERT INTO [dbo].[tblDateTimeConversion_Block](TableName, ColName, StoreName, Sql, BlockRank,BlockCount) 
		SELECT TableName = @TableName, ColName = @DateTimeColumn, @StoreName, Sql = @NonIntegerSql , BlockRank = -2, BlockCount = 0
		RETURN 
	END

	DECLARE @storeCondition NVARCHAR(MAX) = CASE WHEN @storeName IS NULL THEN ' ' ELSE ' AND storeName = ''' + @storeName + ''' ' END 	 

	-- Zero count handling
	DECLARE @sSQL nvarchar(500) = N'SELECT @retvalOUT = COUNT(*) FROM (SELECT TOP ' + CAST((@BlockSize + 1) AS NVARCHAR(10)) + ' * FROM ' + @TableName + ' WHERE [' + @DateTimeColumn + '] IS NOT NULL ' + @storeCondition + ') X'  
	DECLARE @ParmDefinition nvarchar(500) = N'@retvalOUT int OUTPUT'
	DECLARE @retval int   
	EXEC sp_executesql @sSQL, @ParmDefinition, @retvalOUT=@retval OUTPUT
	IF (@retval = 0)
	BEGIN
		INSERT INTO [dbo].[tblDateTimeConversion_Block](TableName, ColName, StoreName, Sql,Converted,BlockRank,BlockCount) 
		SELECT TableName = @TableName, ColName = @DateTimeColumn, @StoreName, Sql = NULL, Converted = 1, BlockRank = 0, BlockCount = 0 
		RETURN
	END

	-- Create formatted list of keys for use in queries

	DECLARE @Values_List NVARCHAR(MAX) = ''
	SELECT @Values_List = @Values_List + '[' + Data + '], ' FROM @Keys
	SET @Values_List = Substring(@Values_List, 1, len(@Values_List) - 1)

	DECLARE @Values_List2 NVARCHAR(MAX) = ''
	SELECT @Values_List2 = @Values_List2 + 'tbl.[' + Data + '], ' FROM @Keys
	SET @Values_List2 = Substring(@Values_List2, 1, len(@Values_List2) - 1)

	DECLARE @Values_RowId NVARCHAR(MAX) = ''
	SELECT @Values_RowId = @Values_RowId + ' REPLACE(STR([' + Data + '], 16), '' '' , ''0'') +' FROM @Keys
	SET @Values_RowId = Substring(@Values_RowId, 1, len(@Values_RowId) - 1)

	DECLARE @Values_RowId2 NVARCHAR(MAX) = ''
	SELECT @Values_RowId2 = @Values_RowId2 + ' REPLACE(STR(tbl.[' + Data + '], 16), '''' '''' , ''''0'''') +' FROM @Keys
	SET @Values_RowId2 = Substring(@Values_RowId2, 1, len(@Values_RowId2) - 1)
	
	DECLARE @Values_MinMaxList NVARCHAR(MAX) = ''
	SELECT @Values_MinMaxList = @Values_MinMaxList + ' [Min' + Data + '], [Max' + Data + '], ' FROM @Keys
	SET @Values_MinMaxList = Substring(@Values_MinMaxList, 1, len(@Values_MinMaxList) - 1)
	
	DECLARE @Values_MinMaxSet NVARCHAR(MAX) = ''
	SELECT @Values_MinMaxSet = @Values_MinMaxSet + ' [Min' + Data + '] = MIN(' + Data + '), [Max' + Data + '] = MAX(' + Data + '),' FROM @Keys
	SET @Values_MinMaxSet = Substring(@Values_MinMaxSet, 1, len(@Values_MinMaxSet) - 1)
	
	DECLARE @Values_Declare NVARCHAR(MAX) = ''
	SELECT @Values_Declare = @Values_Declare + ' [Min' + Data + '] INT NOT NULL, ' + ' [Max' + Data + '] INT NOT NULL, ' FROM @Keys
	
	DECLARE @Values_Condition NVARCHAR(MAX) = ''
	SELECT @Values_Condition = ' [Min' + @Values_Condition + Data + ',' FROM @Keys
	SET @Values_Condition = Substring(@Values_Condition, 1, len(@Values_Condition) - 1)

	DECLARE @Values_Declare2 NVARCHAR(MAX) = ''
	SELECT @Values_Declare2 = @Values_Declare2 + ' [' + Data + '] INT NOT NULL, ' FROM @Keys

	DECLARE @Values_Condition2 NVARCHAR(MAX) = ''
	SELECT @Values_Condition2 = @Values_Condition2 + ' tbl.['+Data+'] = t.['+Data+'] AND' FROM @Keys
	SET @Values_Condition2 = Substring(@Values_Condition2, 1, len(@Values_Condition2) - 3)
	
	DECLARE @SQL NVARCHAR(MAX) = ''
		+ 'DECLARE @DATA AS TABLE( '
		+ '	[MIN] DATETIME NULL, '
		+ '	[MAX] DATETIME NULL, '
		+ '	BlockRank INT NOT NULL, ' 
		+ '	BlockCount INT NOT NULL, '
		+ @Values_Declare
		+ '	IntervalStart VARCHAR(50) NULL, '
		+ '	IntervalEnd	VARCHAR(50) NULL, '
		+ '	ConditionSql NVARCHAR(MAX) NULL, '
		+ '	UpdateSql NVARCHAR(MAX) NULL, '
		+ '	Converted BIT NOT NULL DEFAULT 0 '
		+ ') '
		+ ' '
		+ 'DECLARE @BLOCK AS TABLE([MIN] DATETIME NULL, [MAX] DATETIME NULL, BlockRank INT NOT NULL, ' + @Values_Declare + 'BlockCount INT NOT NULL) '
		+ 'DECLARE @BLOCKROW1000 AS TABLE(BlockRank INT NOT NULL, RowId NVARCHAR(' + CAST(@IntegerPrimaryKeys * 16 AS NVARCHAR(10)) + ') NOT NULL) '
		+ ' '
		+ 'INSERT INTO @BLOCK '
		+ 'SELECT [MIN] = MIN(DT), [MAX] = MAX(DT), BlockRank = ([RANK] - 1) / ' + CAST((@BlockSize) AS NVARCHAR(10)) + ', ' + @Values_MinMaxSet + ', BlockCount = COUNT(*) '
		+ 'FROM ( '
		+ '    SELECT DT = [' + @DateTimeColumn + '], [Rank] = DENSE_RANK() OVER (ORDER BY ' + @Values_List + '), ' + @Values_List + ' '
		+ '    FROM ' + @TableName + ' WITH(NOLOCK) '
		+ '    WHERE [' + @DateTimeColumn + '] IS NOT NULL ' + @storeCondition
		+ '    ) AS RowNr '
		+ 'GROUP BY ((([Rank]) - 1) / ' + CAST((@BlockSize) AS NVARCHAR(10)) + ') '
		+ ' '
		+ 'INSERT INTO @BLOCKROW1000 '
		+ 'SELECT BlockRank = (DENSE_RANK() OVER (ORDER BY [RowID]) - 1), RowID FROM ( '
		+ '    SELECT RowID = ' + @Values_RowId + ' '
		+ '    FROM ( '
		+ '        SELECT ' + @Values_List + ', DENSE_RANK() OVER (ORDER BY ' + @Values_List + ') AS rownum '
		+ '	       FROM ' + @TableName + ' WITH(NOLOCK) '
		+ '        WHERE [' + @DateTimeColumn + '] IS NOT NULL ' + @storeCondition
		+ '        ) AS RowNr '
		+ '    WHERE RowNr.rownum % ' + CAST((@BlockSize) AS NVARCHAR(10)) + ' = 0   '  
		+ '    ) AS Row1000 '
		+ ' '
		+ 'INSERT INTO @DATA '
		+ 'SELECT [MIN], [MAX], Block.BlockRank, BlockCount, ' + @Values_MinMaxList + ', IntervalStart = NULL, IntervalEnd = RowID, ConditionSql = NULL, UpdateSql = NULL, Converted = 0 '
		+ 'FROM @BLOCK Block '
		+ 'LEFT JOIN @BLOCKROW1000	BlockRow1000 '
		+ 'ON Block.BlockRank = BlockRow1000.BlockRank '
		+ 'ORDER BY Block.BlockRank   '
		+ ' '
		+ 'UPDATE d1 SET d1.IntervalStart = d2.IntervalEnd FROM @DATA d1 JOIN @DATA d2 ON d1.BlockRank = d2.BlockRank + 1 '
		+ 'UPDATE @DATA SET IntervalStart = ''' + REPLICATE('0', 16 * @IntegerPrimaryKeys) + ''' WHERE BlockRank = (SELECT MIN(BlockRank) from @DATA) '
		+ 'UPDATE @DATA SET IntervalEnd = ''' + REPLICATE('9', 16 * @IntegerPrimaryKeys) + ''' WHERE BlockRank = (SELECT MAX(BlockRank) from @DATA) '
		+ 'UPDATE @Data SET ConditionSql = '' [' + @DateTimeColumn + '] IS NOT NULL ' + REPLACE(@storeCondition,'''','''''') + ' '' '
	SELECT @SQL = @SQL + ' + '' AND tbl.['+Data+'] >= ''+CAST([Min'+Data+'] AS NVARCHAR(20))+'' AND tbl.['+Data+'] <= ''+CAST([Max'+Data+'] AS NVARCHAR(20))+'' '' ' FROM @Keys v

	IF (@TotalPrimaryKeys>1)
		SET @SQL = @SQL +' + '' AND '+ @Values_RowId2 + ' > '''''' + IntervalStart + '''''' AND ' + @Values_RowId2 + ' <= '''''' + IntervalEnd + '''''' '' '

	DECLARE @UPDATESQL NVARCHAR(MAX) ='
		DECLARE @OffsetTEMP AS TABLE( [IntervalStart] DATETIME NOT NULL,[IntervalEnd] DATETIME NOT NULL, [Offset] FLOAT NOT NULL) 
		DECLARE @MIN DATETIME = ''''[[MIN]]'''', @MAX DATETIME = ''''[[MAX]]'''' 
		INSERT INTO @OffsetTEMP 
		SELECT c.IntervalStart, c.IntervalEnd, c.Offset 
		FROM tblDateTimeConversion_Offset c WITH (NOLOCK)  
		WHERE c.IntervalStart-1 >= @MIN AND c.IntervalEnd+1 <= @MAX OR @MIN between c.IntervalStart-1 and c.IntervalEnd+1 OR @MAX between c.IntervalStart-1 and c.IntervalEnd+1
	
		DECLARE @'+@TableName+'TEMP AS TABLE('+@Values_Declare2+' [' + @DateTimeColumn + '] DATETIME NOT NULL,PRIMARY KEY('+@Values_List+')) 
		INSERT INTO @'+@TableName+'TEMP 
		SELECT '+@Values_List2+', [' + @DateTimeColumn + '] = tbl.[' + @DateTimeColumn + '] + CAST(c.OffSet AS DATETIME)  
		FROM  @OffsetTEMP c
		JOIN ['+@TableName+'] tbl WITH(NOLOCK) ON tbl.[' + @DateTimeColumn + ']>=c.IntervalStart AND tbl.[' + @DateTimeColumn + ']<c.IntervalEnd 
		WHERE [[CONDITION]] 
		OPTION (LOOP JOIN) 
	
		DECLARE @StartTimeStamp DATETIME = SYSDATETIME() 
	
		UPDATE tbl 
		SET tbl.[' + @DateTimeColumn + '] = t.[' + @DateTimeColumn + '] 
		FROM @'+@TableName+'TEMP t 
		JOIN ['+@TableName+'] tbl WITH(ROWLOCK) ON '+@Values_Condition2 + '
		OPTION (LOOP JOIN) 
	
		DECLARE @EndTimeStamp DATETIME = SYSDATETIME() 
		SET @UpdateTimeRETURN = DATEDIFF(MS,@StartTimeStamp,@EndTimeStamp) '

	SET @SQL = @SQL 
		+ 'DECLARE @UpdateSql NVARCHAR(MAX) '
		+ 'SET @UpdateSql = ''' + @UPDATESQL + ' '' '
		+ 'UPDATE @Data SET UpdateSql = @UpdateSql '
		+ 'INSERT INTO [dbo].[tblDateTimeConversion_Block](TableName, ColName, StoreName, Sql,Priority,BlockRank,BlockCount) SELECT TableName = ''' + @TableName + ''', ColName = ''' + @DateTimeColumn + ''', StoreName= ' + COALESCE('''' + @StoreName + '''', 'NULL') + ', Sql = REPLACE(REPLACE(REPLACE(UpdateSql,''[[CONDITION]]'',ConditionSql),''[[MIN]]'',[MIN]),''[[MAX]]'',[MAX]), Priority = BlockRank, BlockRank = d.BlockRank,BlockCount=d.BlockCount FROM @DATA d '

	EXEC (@SQL)

	UPDATE tbl 
	SET [Priority] = f.maxrank-tbl.blockrank + 1
	FROM tblDateTimeConversion_Block tbl 
	JOIN (SELECT * FROM (
		SELECT TableName, MaxRank = MAX(BlockRank) 
		FROM tblDateTimeConversion_Block 
		WHERE Converted = 0 and [Sql] IS NOT NULL 
		GROUP BY TableName) x 
	WHERE MaxRank >= 0) f ON f.TableName = tbl.TableName 
	WHERE tbl.TableName = @TableName AND tbl.ColName = @DateTimeColumn 
END
GO
PRINT N'Creating [dbo].[DateTimeConversion_RunBlocks]...';


GO
CREATE PROCEDURE [dbo].[DateTimeConversion_RunBlocks]
(@Print INT = NULL)
AS
BEGIN
	DECLARE @pkId INT
	DECLARE @tblName nvarchar(128)
	DECLARE @colName nvarchar(128)
	DECLARE @storeName NVARCHAR(375)
	DECLARE @sql nvarchar(MAX)
	DECLARE cur CURSOR LOCAL FOR SELECT pkId, TableName,ColName,[Sql], StoreName FROM [tblDateTimeConversion_Block] WHERE Converted = 0 AND [Sql] IS NOT NULL ORDER BY [Priority]	
	DECLARE @StartTime DATETIME
	DECLARE @EndTime DATETIME
	DECLARE @TotalCount INT
	SELECT @TotalCount = COUNT(*) FROM [tblDateTimeConversion_Block] WHERE Converted = 0 AND [Sql] IS NOT NULL 
	IF (@TotalCount = 0)
		RETURN
	OPEN cur
	FETCH NEXT FROM cur INTO @pkId, @tblName, @colName, @Sql,@storeName
	DECLARE @loops INT = 0
	DECLARE @UpdateTime INT
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		SET @Loops = @Loops + 1
		DECLARE @store NVARCHAR(500) = CASE WHEN @storeName IS NULL THEN '' ELSE ', STORENAME: ' + @storeName END 	 
		IF @Print IS NOT NULL PRINT CAST(@Loops AS NVARCHAR(8)) + ' / ' + CAST(@TotalCount AS NVARCHAR(8)) + ' - PKID: ' + CAST(@pkId AS NVARCHAR(10)) +', TABLE: '+@tblName+', COLUMN: '+@colName + @store + ', TIMESTAMP: ' + CONVERT( VARCHAR(24), GETDATE(), 121)
		IF @Print IS NOT NULL PRINT '			SQL: ' + @sql
		BEGIN TRANSACTION [Transaction]
		BEGIN TRY
			SET @StartTime = GETDATE()
			EXEC sp_executesql @SQL, N'@UpdateTimeRETURN int OUTPUT', @UpdateTimeRETURN = @UpdateTime OUTPUT				
			SET @EndTime = GETDATE()
			UPDATE [tblDateTimeConversion_Block] SET Converted = 1, StartTime = @StartTime, EndTime = @EndTime, UpdateTime = @UpdateTime WHERE pkID = @pkId
			IF @Print IS NOT NULL PRINT 'COMMIT'
			COMMIT TRANSACTION [Transaction]
		END TRY
		BEGIN CATCH
			IF @Print IS NOT NULL PRINT 'ROLLBACK: ' + ERROR_MESSAGE() 
			ROLLBACK TRANSACTION [Transaction]
		END CATCH  
		FETCH NEXT FROM cur INTO @pkId, @tblName, @colName, @Sql, @storeName
	END	
	CLOSE cur
	DEALLOCATE cur
END
GO
PRINT N'Creating [dbo].[DateTimeConversion_InitBlocks]...';


GO
CREATE PROCEDURE [dbo].[DateTimeConversion_InitBlocks]
(@BlockSize INT, @Print INT = NULL)
AS
BEGIN
	IF OBJECT_ID('[dbo].[tblDateTimeConversion_Block]', 'U') IS NOT NULL
	BEGIN
		IF (SELECT COUNT(*) FROM [dbo].[tblDateTimeConversion_Block] WHERE Converted > 0 AND [Sql] IS NOT NULL) > 0 
			RETURN 
		ELSE 
			DROP TABLE [dbo].[tblDateTimeConversion_Block]
	END

	CREATE TABLE [dbo].[tblDateTimeConversion_Block](
		[pkID] [int] IDENTITY(1,1) NOT NULL,		
		[TableName] nvarchar(128) NOT NULL,
		[ColName] nvarchar(128) NOT NULL,
		[StoreName] NVARCHAR(375) NULL,
		[BlockRank] INT NOT NULL,
		[BlockCount] INT NOT NULL,
		[Sql] nvarchar(MAX) NULL,
		[Priority] INT NOT NULL DEFAULT 0,
		[Converted] BIT NOT NULL DEFAULT 0,
		[StartTime] DATETIME NULL,
		[EndTime] DATETIME NULL,
		[UpdateTime] INT NULL,
		[CallTime] AS (DATEDIFF(MS, StartTime,EndTime)),
		CONSTRAINT [PK_tblDateTimeConversion_Block] PRIMARY KEY  CLUSTERED
		(
			[pkID]
		)
	)

	DECLARE @tblName NVARCHAR(128)
	DECLARE @colName NVARCHAR(128)
	DECLARE @storeName NVARCHAR(375)

	DECLARE cur CURSOR LOCAL FOR SELECT TableName, ColName, StoreName FROM [dbo].[tblDateTimeConversion_FieldName]                                  
	DECLARE @TotalCount INT
	DECLARE @loops INT = 0
	SELECT @TotalCount = COUNT(*) FROM [dbo].[tblDateTimeConversion_FieldName]                                                           
	OPEN cur
	FETCH NEXT FROM cur INTO @tblName, @colName, @storeName
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		SET @loops = @loops + 1
		DECLARE @store NVARCHAR(500) = CASE WHEN @storeName IS NULL THEN '' ELSE ', STORENAME: ' + @storeName END 	 
		IF @Print IS NOT NULL PRINT CAST(@Loops AS NVARCHAR(8)) + ' / ' + CAST(@TotalCount AS NVARCHAR(8)) + ' - TABLE: '+@tblName+', COLUMN: '+@colName + @store +', TIMESTAMP: ' + CONVERT( VARCHAR(24), GETDATE(), 121)
		EXEC [dbo].[DateTimeConversion_MakeTableBlocks] @tblName, @colName, @storeName, @BlockSize, @Print		 
		FETCH NEXT FROM cur INTO @tblName, @colName, @storeName
	END	
	CLOSE cur
	DEALLOCATE cur
END
GO
PRINT N'Creating [dbo].[DateTimeConversion_Finalize]...';


GO
CREATE PROCEDURE [dbo].[DateTimeConversion_Finalize]
(@Print INT = NULL)
AS
BEGIN
	IF @Print IS NOT NULL PRINT 'UPDATE DateTimeKind'

	UPDATE tbl 
	SET DateTimeKind = 2
	FROM tblBigTableStoreConfig tbl
	JOIN tblDateTimeConversion_FieldName f ON tbl.StoreName = f.StoreName AND tbl.TableName = f.TableName 

	DECLARE @GetDateTimeKindSql NVARCHAR(MAX) = '
ALTER PROCEDURE [dbo].[sp_GetDateTimeKind]
AS
	-- 0 === Unspecified  
	-- 1 === Local time 
	-- 2 === UTC time 
	RETURN 2

'
	EXEC (@GetDateTimeKindSql)

	IF @Print IS NOT NULL PRINT 'FINISHED'
END

GO

PRINT N'Update complete.';

GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7025

GO
PRINT N'Update complete.';
GO
--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7007)
				select 0, 'Already correct database version'
            else if (@ver = 7006)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
PRINT N'The following operation was generated from a refactoring log file 017676df-a76b-4e52-b4b1-3a0ea4fc3400';

PRINT N'Rename [dbo].[tblContentLanguage].[PublishedVersion] to Version';


GO
EXECUTE sp_rename @objname = N'[dbo].[tblContentLanguage].[PublishedVersion]', @newname = N'Version', @objtype = N'COLUMN';


GO
PRINT N'Dropping [dbo].[tblWorkContent].[IDX_tblWorkContent_StatusFields]...';


GO
DROP INDEX [IDX_tblWorkContent_StatusFields]
    ON [dbo].[tblWorkContent];


GO
PRINT N'Dropping DF__tblContent__Pending__31D75E8D...';


GO
ALTER TABLE [dbo].[tblContent] DROP CONSTRAINT [DF__tblContent__Pending__31D75E8D];


GO
PRINT N'Dropping DF__tblContentLanguage__PendingPublish...';


GO
ALTER TABLE [dbo].[tblContentLanguage] DROP CONSTRAINT [DF__tblContentLanguage__PendingPublish];


GO
PRINT N'Dropping DF__tblWorkPa__HasBe__4F67C174...';


GO
ALTER TABLE [dbo].[tblWorkContent] DROP CONSTRAINT [DF__tblWorkPa__HasBe__4F67C174];


GO
PRINT N'Dropping DF__tblWorkPa__Ready__4D7F7902...';


GO
ALTER TABLE [dbo].[tblWorkContent] DROP CONSTRAINT [DF__tblWorkPa__Ready__4D7F7902];


GO
PRINT N'Dropping DF__tblWorkPa__Rejec__505BE5AD...';


GO
ALTER TABLE [dbo].[tblWorkContent] DROP CONSTRAINT [DF__tblWorkPa__Rejec__505BE5AD];


GO
PRINT N'Dropping DF__tblWorkPa_Delayed...';


GO
ALTER TABLE [dbo].[tblWorkContent] DROP CONSTRAINT [DF__tblWorkPa_Delayed];


GO
PRINT N'Dropping [dbo].[editCheckInContentVersion]...';


GO
DROP PROCEDURE [dbo].[editCheckInContentVersion];


GO
PRINT N'Dropping [dbo].[editCheckOutContentVersion]...';


GO
DROP PROCEDURE [dbo].[editCheckOutContentVersion];


GO
PRINT N'Dropping [dbo].[editRejectCheckedInContentVersion]...';


GO
DROP PROCEDURE [dbo].[editRejectCheckedInContentVersion];


GO
PRINT N'Dropping [dbo].[netMasterLicenseGet]...';


GO
DROP PROCEDURE [dbo].[netMasterLicenseGet];


GO
PRINT N'Dropping [dbo].[netMasterLicenseSet]...';


GO
DROP PROCEDURE [dbo].[netMasterLicenseSet];


GO
PRINT N'Dropping [dbo].[netPageDataLoadVersion]...';


GO
DROP PROCEDURE [dbo].[netPageDataLoadVersion];


GO
PRINT N'Dropping [dbo].[netPageListPaged]...';


GO
DROP PROCEDURE [dbo].[netPageListPaged];


GO
PRINT N'Dropping [dbo].[netPageDataLoad]...';


GO
DROP PROCEDURE [dbo].[netPageDataLoad];


GO
PRINT N'Altering [dbo].[tblWorkContent]...';


GO
ALTER TABLE [dbo].[tblWorkContent]
    ADD [Status] INT DEFAULT (2) NOT NULL;
GO

UPDATE [dbo].[tblWorkContent] 
SET Status = CASE WHEN L.Version=W.pkID THEN 4						
			WHEN W.HasBeenPublished=1 THEN 5							
			WHEN W.Rejected=1 THEN 1									
			WHEN W.ReadyToPublish=1  AND W.DelayedPublish = 1 THEN 6	
			WHEN W.ReadyToPublish=1 THEN 3								
			ELSE 2	
			END
FROM [dbo].[tblWorkContent] AS W INNER JOIN [dbo].[tblContentLanguage] AS L ON W.fkContentID = L.fkContentID
WHERE L.fkLanguageBranchID = W.fkLanguageBranchID


ALTER TABLE [dbo].[tblWorkContent] DROP COLUMN [DelayedPublish], COLUMN [HasBeenPublished], COLUMN [ReadyToPublish], COLUMN [Rejected];
GO
PRINT N'Altering [dbo].[tblContent]...';


GO
ALTER TABLE [dbo].[tblContent] DROP COLUMN [PendingPublish], COLUMN [PublishedVersion];


GO
PRINT N'Altering [dbo].[tblContentLanguage]...';
ALTER TABLE [dbo].[tblContentLanguage]
    ADD [Status] INT DEFAULT (2) NOT NULL;
GO

UPDATE [dbo].[tblContentLanguage] 
SET Status = W.Status
FROM [dbo].[tblWorkContent] AS W INNER JOIN [dbo].[tblContentLanguage] AS L ON W.pkID = L.Version
GO

UPDATE [dbo].[tblContentLanguage] 
SET Status = W.Status, Version = W.pkID
FROM [dbo].[tblWorkContent] AS W INNER JOIN [dbo].[tblContentLanguage] AS L ON W.fkContentID = L.fkContentID
WHERE L.fkLanguageBranchID = W.fkLanguageBranchID AND L.Version IS NULL
AND (W.pkID = (SELECT TOP 1 pkID 
			FROM tblWorkContent AS Versions
			WHERE Versions.fkContentID=L.fkContentID AND Versions.fkLanguageBranchID=L.fkLanguageBranchID
			ORDER BY Versions.Saved DESC))

GO
ALTER TABLE [dbo].[tblContentLanguage] DROP COLUMN [PendingPublish];



GO
PRINT N'Creating [dbo].[tblContentLanguage].[IDX_tblContentLanguage_Version]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblContentLanguage_Version]
    ON [dbo].[tblContentLanguage]([Version] ASC);


GO
PRINT N'Altering [dbo].[tblWorkContent]...';



GO
PRINT N'Creating [dbo].[tblWorkContent].[IDX_tblWorkContent_StatusFields]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblWorkContent_StatusFields]
    ON [dbo].[tblWorkContent]([Status] ASC);


GO
PRINT N'Creating FK_tblContentLanguage_tblWorkContent...';


GO
ALTER TABLE [dbo].[tblContentLanguage] WITH NOCHECK
    ADD CONSTRAINT [FK_tblContentLanguage_tblWorkContent] FOREIGN KEY ([Version]) REFERENCES [dbo].[tblWorkContent] ([pkID]);


GO
PRINT N'Altering [dbo].[tblPageLanguage]...';


GO
ALTER VIEW [dbo].[tblPageLanguage]
AS
SELECT
	[fkContentID] AS fkPageID,
	[fkLanguageBranchID],
	[ContentLinkGUID] AS PageLinkGUID,
	[fkFrameID],
	[CreatorName],
    [ChangedByName],
    [ContentGUID] AS PageGUID,
    [Name],
    [URLSegment],
    [LinkURL],
	[BlobUri],
	[ThumbnailUri],
    [ExternalURL],
    [AutomaticLink],
    [FetchData],
    CASE WHEN Status = 4 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS PendingPublish,
    [Created],
    [Changed],
    [Saved],
    [StartPublish],
    [StopPublish],
    [Version],
	[Status]

FROM    dbo.tblContentLanguage
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
		[ExternalFolderID],
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
PRINT N'Altering [dbo].[tblWorkPage]...';


GO
ALTER VIEW [dbo].[tblWorkPage]
AS
SELECT
	[pkID],
    [fkContentID] AS fkPageID,
    [fkMasterVersionID],
    [ContentLinkGUID] AS PageLinkGUID,
    [fkFrameID],
    [ArchiveContentGUID] as ArchivePageGUID,
    [ChangedByName],
    [NewStatusByName],
    [Name],
    [URLSegment],
    [LinkURL],
	[BlobUri],
	[ThumbnailUri],
    [ExternalURL],
    [VisibleInMenu],
    [LinkType],
    [Created],
    [Saved],
    [StartPublish],
    [StopPublish],
    [ChildOrderRule],
    [PeerOrder],
    CASE WHEN Status = 3 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS ReadyToPublish,
    [ChangedOnPublish],
    CASE WHEN Status = 5 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS HasBeenPublished,
    CASE WHEN Status = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS Rejected,
    CASE WHEN Status = 6 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS DelayedPublish,
    [RejectComment],
    [fkLanguageBranchID],
	[CommonDraft]
FROM    dbo.tblWorkContent
GO
PRINT N'Altering [dbo].[netCategoryContentLoad]...';


GO
ALTER PROCEDURE [dbo].[netCategoryContentLoad]
(
	@ContentID			INT,
	@VersionID		INT,
	@CategoryType	INT,
	@LanguageBranch	NCHAR(17) = NULL,
	@ScopeName NVARCHAR(450)
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @LangBranchID NCHAR(17);
	DECLARE @LanguageSpecific INT;

	IF(@VersionID = 0)
			SET @VersionID = NULL;
	IF @VersionID IS NOT NULL AND @LanguageBranch IS NOT NULL
	BEGIN
		IF NOT EXISTS(	SELECT
							LanguageID
						FROM
							tblWorkContent 
						INNER JOIN
							tblLanguageBranch
						ON
							tblWorkContent.fkLanguageBranchID = tblLanguageBranch.pkID
						WHERE
							LanguageID = @LanguageBranch
						AND
							tblWorkContent.pkID = @VersionID)
			RAISERROR('@LanguageBranch %s is not the same as Language Branch for page version %d' ,16,1, @LanguageBranch,@VersionID)
	END
	
	IF(@LanguageBranch IS NOT NULL)
		SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID = @LanguageBranch;
	ELSE
		SELECT @LangBranchID = fkLanguageBranchID FROM tblWorkContent WHERE pkID = @VersionID;
	
	IF(@CategoryType <> 0)
		SELECT @LanguageSpecific = LanguageSpecific FROM tblPageDefinition WHERE pkID = @CategoryType;
	ELSE
		SET @LanguageSpecific = 0;

	IF @LangBranchID IS NULL AND @LanguageSpecific > 2
		RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)

	IF @LanguageSpecific < 3 AND @VersionID IS NOT NULL
	BEGIN
		IF EXISTS(SELECT pkID FROM tblContent WHERE pkID=@ContentID AND fkMasterLanguageBranchID<>@LangBranchID)
		BEGIN
			SELECT @VersionID = tblContentLanguage.Version 
				FROM tblContentLanguage 
				INNER JOIN tblContent ON tblContent.pkID=tblContentLanguage.fkContentID
				WHERE tblContent.pkID=@ContentID AND tblContentLanguage.fkLanguageBranchID=tblContent.fkMasterLanguageBranchID			
		END
	END

	IF (@VersionID IS NOT NULL)
	BEGIN
		/* Get info from tblWorkContentCategory */
		SELECT
			fkCategoryID AS CategoryID
		FROM
			tblWorkContentCategory
		WHERE
			ScopeName=@ScopeName AND
			fkWorkContentID=@VersionID
	END
	ELSE
	BEGIN
		/* Get info from tblContentcategory */
		SELECT
			fkCategoryID AS CategoryID
		FROM
			tblContentCategory
		WHERE
			ScopeName=@ScopeName AND
			fkContentID=@ContentID AND
			(fkLanguageBranchID=@LangBranchID OR @LanguageSpecific < 3)
	END
	
	RETURN 0
END
GO
PRINT N'Altering [dbo].[editDeletePageInternal]...';


GO
ALTER PROCEDURE [dbo].[editDeletePageInternal]
(
    @PageID INT,
    @ForceDelete INT = NULL
)
AS
BEGIN

	SET NOCOUNT ON
	SET XACT_ABORT ON
	
-- STRUCTURE
	
	-- Make sure we dump structure and features like fetch data before we start off repairing links for pages that should not get deleted
	UPDATE 
	    tblPage 
	SET 
	    fkParentID = NULL,
	    ArchivePageGUID=NULL 
	WHERE 
	    pkID IN ( SELECT pkID FROM #pages )

	UPDATE 
	    tblContentLanguage
	SET 
	    Version = NULL 
	WHERE 
	    fkContentID IN ( SELECT pkID FROM #pages )
	    
	UPDATE 
	    tblWorkPage 
	SET 
	    fkMasterVersionID=NULL,
	    PageLinkGUID=NULL,
	    ArchivePageGUID=NULL 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM #pages )

-- VERSION DATA

	-- Delete page links, archiving and fetch data pointing to us from external pages
	DELETE FROM 
	    tblWorkProperty 
	WHERE 
	    PageLink IN ( SELECT pkID FROM #pages )
	    
	UPDATE 
	    tblWorkPage 
	SET 
	    ArchivePageGUID = NULL 
	WHERE 
	    ArchivePageGUID IN ( SELECT PageGUID FROM #pages )
	    
	UPDATE 
	    tblWorkPage 
	SET 
	    PageLinkGUID = NULL, 
	    LinkType=0,
	    LinkURL=
		(
			SELECT TOP 1 
			      '~/link/' + CONVERT(NVARCHAR(32),REPLACE((select top 1 PageGUID FROM tblPage where tblPage.pkID = tblWorkPage.fkPageID),'-','')) + '.aspx'
			FROM 
			    tblPageType
			WHERE 
			    tblPageType.pkID=(SELECT fkPageTypeID FROM tblPage WHERE tblPage.pkID=tblWorkPage.fkPageID)
		)
	 WHERE 
	    PageLinkGUID IN ( SELECT PageGUID FROM #pages )
	
	-- Remove workproperties,workcategories and finally the work versions themselves
	DELETE FROM 
	    tblWorkProperty 
	WHERE 
	    fkWorkPageID IN ( SELECT pkID FROM tblWorkPage WHERE fkPageID IN ( SELECT pkID FROM #pages ) )
	    
	DELETE FROM 
	    tblWorkCategory 
	WHERE 
	    fkWorkPageID IN ( SELECT pkID FROM tblWorkPage WHERE fkPageID IN ( SELECT pkID FROM #pages ) )
	    
	DELETE FROM 
	    tblWorkPage 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM #pages )

-- PUBLISHED PAGE DATA

	IF (@ForceDelete IS NOT NULL)
	BEGIN
		DELETE FROM 
		    tblProperty 
		WHERE 
		    PageLink IN (SELECT pkID FROM #pages)
	END
	ELSE
	BEGIN
		/* Default action: Only delete references from pages in wastebasket */
		DELETE FROM 
			tblProperty
		FROM 
		    tblProperty AS P
		INNER JOIN 
		    tblPage ON P.fkPageID=tblPage.pkID
		WHERE
			tblPage.Deleted=1 AND
			P.PageLink IN (SELECT pkID FROM #pages)
	END

	DELETE FROM 
	    tblPropertyDefault 
	WHERE 
	    PageLink IN ( SELECT pkID FROM #pages )
	    
	UPDATE 
	    tblPage 
	SET 
	    ArchivePageGUID = NULL 
	WHERE 
	    ArchivePageGUID IN ( SELECT PageGUID FROM #pages )

	-- Remove fetch data from any external pages pointing to us

	UPDATE 
	    tblPageLanguage 
	SET     
	    PageLinkGUID = NULL, 
	    FetchData=0,
	    LinkURL=
		(
			SELECT TOP 1 
		      '~/link/' + CONVERT(NVARCHAR(32),REPLACE((select top 1 PageGUID FROM tblPage where tblPage.pkID = tblPageLanguage.fkPageID),'-','')) + '.aspx'
			FROM 
			    tblPageType
			WHERE 
			    tblPageType.pkID=(SELECT tblPage.fkPageTypeID FROM tblPage WHERE tblPage.pkID=tblPageLanguage.fkPageID)
		)
	 WHERE 
	    PageLinkGUID IN ( SELECT PageGUID FROM #pages )

	-- Remove ALC, categories and the properties
	DELETE FROM 
	    tblCategoryPage 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM #pages )
	    
	DELETE FROM 
	    tblProperty 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM #pages )
	    
	DELETE FROM 
	    tblContentAccess 
	WHERE 
	    fkContentID IN ( SELECT pkID FROM #pages )

-- KEYWORDS AND INDEXING
	
	DELETE FROM 
	    tblContentSoftlink
	WHERE 
	    fkOwnerContentID IN ( SELECT pkID FROM #pages )

-- PAGETYPES
	    
	UPDATE 
	    tblPageTypeDefault 
	SET 
	    fkArchivePageID=NULL 
	WHERE fkArchivePageID IN (SELECT pkID FROM #pages)

-- PAGE/TREE

	DELETE FROM 
	    tblTree 
	WHERE 
	    fkChildID IN ( SELECT pkID FROM #pages )
	    
	DELETE FROM 
	    tblTree 
	WHERE 
	    fkParentID IN ( SELECT pkID FROM #pages )
	    
	DELETE FROM 
	    tblPageLanguage 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM #pages )
	    
	DELETE FROM 
	    tblPageLanguageSetting 
	WHERE 
	    fkPageID IN ( SELECT pkID FROM #pages )
   
	DELETE FROM
	    tblPage 
	WHERE 
	    pkID IN ( SELECT pkID FROM #pages )

END
GO
PRINT N'Altering [dbo].[editDeleteProperty]...';


GO
ALTER PROCEDURE dbo.editDeleteProperty
(
	@PageID			INT,
	@WorkPageID		INT,
	@PageDefinitionID	INT,
	@Override		BIT = 0,
	@LanguageBranch		NCHAR(17) = NULL,
	@ScopeName	NVARCHAR(450) = NULL
)
AS
BEGIN
	DECLARE @LangBranchID NCHAR(17);
	SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID = @LanguageBranch
	IF @LangBranchID IS NULL 
	BEGIN 
		if @LanguageBranch IS NOT NULL
			RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)
		else
			SET @LangBranchID = -1
	END

	DECLARE @IsLanguagePublished BIT;
	IF EXISTS(SELECT fkContentID FROM tblContentLanguage 
		WHERE fkContentID = @PageID AND fkLanguageBranchID = CAST(@LangBranchID AS INT) AND [Status] = 4)
		SET @IsLanguagePublished = 1
	ELSE
		SET @IsLanguagePublished = 0
	
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @retval INT
	SET @retval = 0
	
		IF (@WorkPageID IS NOT NULL)
		BEGIN
			/* This only applies to categories, but since PageDefinitionID is unique
				between all properties it is safe to blindly delete like this */
			DELETE FROM
				tblWorkContentCategory
			WHERE
				fkWorkContentID = @WorkPageID
			AND
				CategoryType = @PageDefinitionID
			AND
				(@ScopeName IS NULL OR ScopeName = @ScopeName)

			DELETE FROM
				tblWorkProperty
			WHERE
				fkWorkPageID = @WorkPageID
			AND
				fkPageDefinitionID = @PageDefinitionID
			AND 
				((@ScopeName IS NULL AND ScopeName IS NULL) OR (@ScopeName = ScopeName))
		END
		ELSE
		BEGIN

			/* Might be dynamic properties */
			DELETE FROM
				tblContentCategory
			WHERE
				fkContentID = @PageID
			AND
				CategoryType = @PageDefinitionID
			AND
				(@ScopeName IS NULL OR ScopeName = @ScopeName)
			AND
			(
				@LanguageBranch IS NULL
			OR
				@LangBranchID = fkLanguageBranchID
			)


			IF (@Override = 1)
			BEGIN
				DELETE FROM
					tblProperty
				WHERE
					fkPageDefinitionID = @PageDefinitionID
				AND
					fkPageID IN (SELECT fkChildID FROM tblTree WHERE fkParentID = @PageID)
				AND
				(
					@LanguageBranch IS NULL
				OR
					@LangBranchID = tblProperty.fkLanguageBranchID
				)
				AND 
					((@ScopeName IS NULL AND ScopeName IS NULL) OR (@ScopeName = ScopeName))
				SET @retval = 1
			END
		END
		
		/* When no version is published we save value in tblProperty as well, so the property also need to be removed from tblProperty*/
		IF (@WorkPageID IS NULL OR @IsLanguagePublished = 0)
		BEGIN
			DELETE FROM
				tblProperty
			WHERE
				fkPageID = @PageID
			AND 
				fkPageDefinitionID = @PageDefinitionID  
			AND
			(
				@LanguageBranch IS NULL
			OR
				@LangBranchID = tblProperty.fkLanguageBranchID
			)
			AND
				((@ScopeName IS NULL AND ScopeName IS NULL) OR (@ScopeName = ScopeName))
		END
			
	RETURN @retval
END
GO
PRINT N'Altering [dbo].[editSavePropertyCategory]...';


GO
ALTER PROCEDURE [dbo].[editSavePropertyCategory]
(
	@PageID				INT,
	@WorkPageID			INT,
	@PageDefinitionID	INT,
	@Override			BIT,
	@CategoryString		NVARCHAR(2000),
	@LanguageBranch		NCHAR(17) = NULL,
	@ScopeName			nvarchar(450) = NULL
)
AS
BEGIN

	SET NOCOUNT	ON
	SET XACT_ABORT ON
	DECLARE	@PageIDString			NVARCHAR(20)
	DECLARE	@PageDefinitionIDString	NVARCHAR(20)
	DECLARE @DynProp INT
	DECLARE @retval	INT
	SET @retval = 0

	DECLARE @LangBranchID NCHAR(17);
	IF (@WorkPageID <> 0)
		SELECT @LangBranchID = fkLanguageBranchID FROM tblWorkPage WHERE pkID = @WorkPageID
	ELSE
		SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID = @LanguageBranch

	IF @LangBranchID IS NULL 
	BEGIN 
		if @LanguageBranch IS NOT NULL
			RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)
		else
			SET @LangBranchID = 1
	END

	DECLARE @IsLanguagePublished BIT;
	IF EXISTS(SELECT fkContentID FROM tblContentLanguage 
		WHERE fkContentID = @PageID AND fkLanguageBranchID = CAST(@LangBranchID AS INT) AND Status = 4)
		SET @IsLanguagePublished = 1
	ELSE
		SET @IsLanguagePublished = 0

	SELECT @DynProp=pkID FROM tblPageDefinition WHERE pkID=@PageDefinitionID AND fkPageTypeID IS NULL
	IF (@WorkPageID IS NOT NULL)
	BEGIN
		/* Never store dynamic properties in work table */
		IF (@DynProp IS NOT NULL)
			GOTO cleanup
				
		/* Remove all categories */
		SET @PageIDString = CONVERT(NVARCHAR(20), @WorkPageID)
		SET @PageDefinitionIDString = CONVERT(NVARCHAR(20), @PageDefinitionID)
		DELETE FROM tblWorkContentCategory WHERE fkWorkContentID=@WorkPageID AND ScopeName=@ScopeName
		/* Insert new categories */
		IF (LEN(@CategoryString) > 0)
		BEGIN
			EXEC (N'INSERT INTO tblWorkContentCategory (fkWorkContentID, fkCategoryID, CategoryType, ScopeName) SELECT ' + @PageIDString + N',pkID,' + @PageDefinitionIDString + N', ''' + @ScopeName + N''' FROM tblCategory WHERE pkID IN (' + @CategoryString +N')' )
		END
		
		/* Finally update the property table */
		IF (@PageDefinitionID <> 0)
		BEGIN
			IF EXISTS(SELECT fkWorkContentID FROM tblWorkContentProperty WHERE fkWorkContentID=@WorkPageID AND fkPropertyDefinitionID=@PageDefinitionID AND ScopeName=@ScopeName)
				UPDATE tblWorkContentProperty SET Number=@PageDefinitionID WHERE fkWorkContentID=@WorkPageID 
					AND fkPropertyDefinitionID=@PageDefinitionID
					AND ((@ScopeName IS NULL AND ScopeName IS NULL) OR (@ScopeName = ScopeName))
			ELSE
				INSERT INTO tblWorkContentProperty (fkWorkContentID, fkPropertyDefinitionID, Number, ScopeName) VALUES (@WorkPageID, @PageDefinitionID, @PageDefinitionID, @ScopeName)
		END
	END
	
	IF (@WorkPageID IS NULL OR @IsLanguagePublished = 0)
	BEGIN
		/* Insert or update property */
		/* Remove all categories */
		SET @PageIDString = CONVERT(NVARCHAR(20), @PageID)
		SET @PageDefinitionIDString = CONVERT(NVARCHAR(20), @PageDefinitionID)
		DELETE FROM tblContentCategory WHERE fkContentID=@PageID AND ScopeName=@ScopeName
		AND fkLanguageBranchID=@LangBranchID
		
		/* Insert new categories */
		IF (LEN(@CategoryString) > 0)
		BEGIN
			EXEC (N'INSERT INTO tblContentCategory (fkContentID, fkCategoryID, CategoryType, fkLanguageBranchID, ScopeName) SELECT ' + @PageIDString + N',pkID,' + @PageDefinitionIDString + N', ' + @LangBranchID + N', ''' + @ScopeName + N''' FROM tblCategory WHERE pkID IN (' + @CategoryString +N')' )
		END
		
		/* Finally update the property table */
		IF (@PageDefinitionID <> 0)
		BEGIN
			IF EXISTS(SELECT fkContentID FROM tblContentProperty WHERE fkContentID=@PageID AND fkPropertyDefinitionID=@PageDefinitionID 
						AND fkLanguageBranchID=@LangBranchID AND ScopeName=@ScopeName)
				UPDATE tblContentProperty SET Number=@PageDefinitionID WHERE fkContentID=@PageID AND fkPropertyDefinitionID=@PageDefinitionID
						AND fkLanguageBranchID=@LangBranchID
						AND ((@ScopeName IS NULL AND ScopeName IS NULL) OR (@ScopeName = ScopeName))
			ELSE
				INSERT INTO tblContentProperty (fkContentID, fkPropertyDefinitionID, Number, fkLanguageBranchID, ScopeName) VALUES (@PageID, @PageDefinitionID, @PageDefinitionID, @LangBranchID, @ScopeName)
		END
				
		/* Override dynamic property definitions below the current level */
		IF (@DynProp IS NOT NULL)
		BEGIN
			IF (@Override = 1)
				DELETE FROM tblContentProperty WHERE fkPropertyDefinitionID=@PageDefinitionID AND fkContentID IN (SELECT fkChildID FROM tblTree WHERE fkParentID=@PageID)
			SET @retval = 1
		END
	END
cleanup:		
	
	RETURN @retval
END
GO
PRINT N'Altering [dbo].[netPageChangeMasterLanguage]...';


GO
ALTER PROCEDURE [dbo].[netPageChangeMasterLanguage]
(
	@PageID						INT,
	@NewMasterLanguageBranchID	INT
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @OldMasterLanguageBranchID INT;
	DECLARE @LastNewMasterLanguageVersion INT;
	DECLARE @LastOldMasterLanguageVersion INT;
	SET @OldMasterLanguageBranchID = (SELECT fkMasterLanguageBranchID FROM tblPage WHERE pkID = @PageID);

	IF(@NewMasterLanguageBranchID = @OldMasterLanguageBranchID)
		RETURN -1;

	SET @LastNewMasterLanguageVersion = (SELECT [Version] FROM tblPageLanguage WHERE fkPageID = @PageID AND fkLanguageBranchID = @NewMasterLanguageBranchID AND PendingPublish = 0)
	IF (@LastNewMasterLanguageVersion IS NULL)
		RETURN -1;
	SET @LastOldMasterLanguageVersion = (SELECT PublishedVersion FROM tblPage WHERE pkID = @PageID)
	IF (@LastOldMasterLanguageVersion IS NULL)
		RETURN -1
	
	--Do the actual change of master language branch
	UPDATE
		tblPage
	SET
		tblPage.fkMasterLanguageBranchID = @NewMasterLanguageBranchID
	WHERE
		pkID = @PageID

	--Update tblProperty for common properties
	UPDATE
		tblProperty
	SET
		fkLanguageBranchID = @NewMasterLanguageBranchID
	FROM
		tblProperty
	INNER JOIN
		tblPageDefinition
	ON
		tblProperty.fkPageDefinitionID = tblPageDefinition.pkID
	WHERE
		LanguageSpecific < 3
	AND
		fkPageID = @PageID

	--Update tblCategoryPage for builtin and common categories
	UPDATE
		tblCategoryPage
	SET
		fkLanguageBranchID = @NewMasterLanguageBranchID
	FROM
		tblCategoryPage
	LEFT JOIN
		tblPageDefinition
	ON
		tblCategoryPage.CategoryType = tblPageDefinition.pkID
	WHERE
		(LanguageSpecific < 3
	OR
		LanguageSpecific IS NULL)
	AND
		fkPageID = @PageID

	--Move work categories and properties between the last versions of the languages
	UPDATE
		tblWorkProperty
	SET
		fkWorkPageID = @LastNewMasterLanguageVersion
	FROM
		tblWorkProperty
	INNER JOIN
		tblPageDefinition
	ON
		tblWorkProperty.fkPageDefinitionID = tblPageDefinition.pkID
	WHERE
		LanguageSpecific < 3
	AND
		fkWorkPageID = @LastOldMasterLanguageVersion

	UPDATE
		tblWorkCategory
	SET
		fkWorkPageID = @LastNewMasterLanguageVersion
	FROM
		tblWorkCategory
	LEFT JOIN
		tblPageDefinition
	ON
		tblWorkCategory.CategoryType = tblPageDefinition.pkID
	WHERE
		(LanguageSpecific < 3
	OR
		LanguageSpecific IS NULL)
	AND
		fkWorkPageID = @LastOldMasterLanguageVersion


	--Remove any remaining common properties for old master language versions
	DELETE FROM
		tblWorkProperty
	FROM
		tblWorkProperty
	INNER JOIN
		tblPageDefinition
	ON
		tblWorkProperty.fkPageDefinitionID = tblPageDefinition.pkID
	WHERE
		LanguageSpecific < 3
	AND
		fkWorkPageID IN (SELECT pkID FROM tblWorkPage WHERE fkPageID = @PageID AND fkLanguageBranchID = @OldMasterLanguageBranchID)

	--Remove any remaining common categories for old master language versions
	DELETE FROM
		tblWorkCategory
	FROM
		tblWorkCategory
	LEFT JOIN
		tblPageDefinition
	ON
		tblWorkCategory.CategoryType = tblPageDefinition.pkID
	WHERE
		(LanguageSpecific < 3
	OR
		LanguageSpecific IS NULL)
	AND
		fkWorkPageID IN (SELECT pkID FROM tblWorkPage WHERE fkPageID = @PageID AND fkLanguageBranchID = @OldMasterLanguageBranchID)

	RETURN 0
END
GO
PRINT N'Altering [dbo].[netPageDeleteLanguage]...';


GO
ALTER PROCEDURE dbo.netPageDeleteLanguage
(
	@PageID			INT,
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
		RAISERROR (N'netPageDeleteLanguage: LanguageBranchID is null, possibly empty table tblLanguageBranch', 16, 1)
		RETURN 0
	END

	IF EXISTS( SELECT * FROM tblPage WHERE pkID=@PageID AND fkMasterLanguageBranchID=@LangBranchID )
	BEGIN
		RAISERROR (N'netPageDeleteLanguage: Cannot delete master language branch', 16, 1)
		RETURN 0
	END

	IF NOT EXISTS( SELECT * FROM tblPageLanguage WHERE fkPageID=@PageID AND fkLanguageBranchID=@LangBranchID )
	BEGIN
		RAISERROR (N'netPageDeleteLanguage: Language does not exist on page', 16, 1)
		RETURN 0
	END

	UPDATE tblWorkPage SET fkMasterVersionID=NULL WHERE pkID IN (SELECT pkID FROM tblWorkPage WHERE fkPageID=@PageID AND fkLanguageBranchID=@LangBranchID)
    
	DELETE FROM tblWorkProperty WHERE fkWorkPageID IN (SELECT pkID FROM tblWorkPage WHERE fkPageID=@PageID AND fkLanguageBranchID=@LangBranchID)
	DELETE FROM tblWorkCategory WHERE fkWorkPageID IN (SELECT pkID FROM tblWorkPage WHERE fkPageID=@PageID AND fkLanguageBranchID=@LangBranchID)
	DELETE FROM tblPageLanguage WHERE fkPageID=@PageID AND fkLanguageBranchID=@LangBranchID
	DELETE FROM tblWorkPage WHERE fkPageID=@PageID AND fkLanguageBranchID=@LangBranchID

	DELETE FROM tblProperty FROM tblProperty
	INNER JOIN tblPageDefinition ON tblPageDefinition.pkID=tblProperty.fkPageDefinitionID
	WHERE fkPageID=@PageID 
	AND fkLanguageBranchID=@LangBranchID
	AND fkPageTypeID IS NOT NULL
	
	DELETE FROM tblCategoryPage WHERE fkPageID=@PageID AND fkLanguageBranchID=@LangBranchID
		
	RETURN 1

END
GO
PRINT N'Altering [dbo].[netPropertySave]...';


GO
ALTER PROCEDURE [dbo].[netPropertySave]
(
	@PageID				INT,
	@WorkPageID			INT,
	@PageDefinitionID	INT,
	@Override			BIT,
	@LanguageBranch		NCHAR(17) = NULL,
	@ScopeName			NVARCHAR(450) = NULL,
--Per Type:
	@Number				INT = NULL,
	@Boolean			BIT = 0,
	@Date				DATETIME = NULL,
	@FloatNumber		FLOAT = NULL,
	@PageType			INT = NULL,
	@String				NVARCHAR(450) = NULL,
	@LinkGuid			uniqueidentifier = NULL,
	@PageLink			INT = NULL,
	@LongString			NVARCHAR(MAX) = NULL


)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @LangBranchID NCHAR(17);
	IF (@WorkPageID <> 0)
		SELECT @LangBranchID = fkLanguageBranchID FROM tblWorkPage WHERE pkID = @WorkPageID
	ELSE
		SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID = @LanguageBranch

	IF @LangBranchID IS NULL 
	BEGIN 
		if @LanguageBranch IS NOT NULL
			RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)
		else
			SET @LangBranchID = 1
	END

	DECLARE @IsLanguagePublished BIT;
	IF EXISTS(SELECT fkContentID FROM tblContentLanguage 
		WHERE fkContentID = @PageID AND fkLanguageBranchID = CAST(@LangBranchID AS INT) AND Status = 4)
		SET @IsLanguagePublished = 1
	ELSE
		SET @IsLanguagePublished = 0
	
	DECLARE @DynProp INT
	DECLARE @retval	INT
	SET @retval = 0
	
		SELECT
			@DynProp = pkID
		FROM
			tblPageDefinition
		WHERE
			pkID = @PageDefinitionID
		AND
			fkPageTypeID IS NULL

		IF (@WorkPageID IS NOT NULL)
		BEGIN
			/* Never store dynamic properties in work table */
			IF (@DynProp IS NOT NULL)
				GOTO cleanup
				
			/* Insert or update property */
			IF EXISTS(SELECT fkWorkPageID FROM tblWorkProperty 
				WHERE fkWorkPageID=@WorkPageID AND fkPageDefinitionID=@PageDefinitionID AND ((@ScopeName IS NULL AND ScopeName IS NULL) OR (@ScopeName = ScopeName)))
				UPDATE
					tblWorkProperty
				SET
					ScopeName = @ScopeName,
					Number = @Number,
					Boolean = @Boolean,
					[Date] = @Date,
					FloatNumber = @FloatNumber,
					PageType = @PageType,
					String = @String,
					LinkGuid = @LinkGuid,
					PageLink = @PageLink,
					LongString = @LongString
				WHERE
					fkWorkPageID = @WorkPageID
				AND
					fkPageDefinitionID = @PageDefinitionID
				AND 
					((@ScopeName IS NULL AND ScopeName IS NULL) OR (@ScopeName = ScopeName))
			ELSE
				INSERT INTO
					tblWorkProperty
					(fkWorkPageID,
					fkPageDefinitionID,
					ScopeName,
					Number,
					Boolean,
					[Date],
					FloatNumber,
					PageType,
					String,
					LinkGuid,
					PageLink,
					LongString)
				VALUES
					(@WorkPageID,
					@PageDefinitionID,
					@ScopeName,
					@Number,
					@Boolean,
					@Date,
					@FloatNumber,
					@PageType,
					@String,
					@LinkGuid,
					@PageLink,
					@LongString)
		END
		
		/* For published or languages where no version is published we save value in tblProperty as well. Reason for this is that if when page is loaded
		through tblProperty (typically netPageListPaged) the page gets populated correctly. */
		IF (@WorkPageID IS NULL OR @IsLanguagePublished = 0)
		BEGIN
			/* Insert or update property */
			IF EXISTS(SELECT fkPageID FROM tblProperty 
				WHERE fkPageID = @PageID AND fkPageDefinitionID = @PageDefinitionID  AND
					((@ScopeName IS NULL AND ScopeName IS NULL) OR (@ScopeName = ScopeName)) AND @LangBranchID = tblProperty.fkLanguageBranchID)
				UPDATE
					tblProperty
				SET
					ScopeName = @ScopeName,
					Number = @Number,
					Boolean = @Boolean,
					[Date] = @Date,
					FloatNumber = @FloatNumber,
					PageType = @PageType,
					String = @String,
					LinkGuid = @LinkGuid,
					PageLink = @PageLink,
					LongString = @LongString
				WHERE
					fkPageID = @PageID
				AND
					fkPageDefinitionID = @PageDefinitionID
				AND 
					((@ScopeName IS NULL AND ScopeName IS NULL) OR (@ScopeName = ScopeName))
				AND
					@LangBranchID = tblProperty.fkLanguageBranchID
			ELSE
				INSERT INTO
					tblProperty
					(fkPageID,
					fkPageDefinitionID,
					ScopeName,
					Number,
					Boolean,
					[Date],
					FloatNumber,
					PageType,
					String,
					LinkGuid,
					PageLink,
					LongString,
					fkLanguageBranchID)
				VALUES
					(@PageID,
					@PageDefinitionID,
					@ScopeName,
					@Number,
					@Boolean,
					@Date,
					@FloatNumber,
					@PageType,
					@String,
					@LinkGuid,
					@PageLink,
					@LongString,
					@LangBranchID)
				
			/* Override dynamic property definitions below the current level */
			IF (@DynProp IS NOT NULL)
			BEGIN
				IF (@Override = 1)
					DELETE FROM
						tblProperty
					WHERE
						fkPageDefinitionID = @PageDefinitionID
					AND
					(	
						@LanguageBranch IS NULL
					OR
						@LangBranchID = tblProperty.fkLanguageBranchID
					)
					AND
						fkPageID
					IN
						(SELECT fkChildID FROM tblTree WHERE fkParentID = @PageID)
				SET @retval = 1
			END
		END
cleanup:		
		
	RETURN @retval
END
GO
PRINT N'Altering [dbo].[netReportSimpleAddresses]...';


GO
-- Return a list of pages in a particular branch of the tree changed between a start date and a stop date
ALTER PROCEDURE [dbo].[netReportSimpleAddresses](
	@PageID int,
	@Language int = -1,
	@PageSize int,
	@PageNumber int = 0,
	@SortColumn varchar(40) = 'ExternalURL',
	@SortDescending bit = 0
)
AS
BEGIN
	SET NOCOUNT ON;

	WITH PageCTE AS
	(
		SELECT ROW_NUMBER() OVER(ORDER BY 
			-- Page Name Sorting
			CASE WHEN @SortColumn = 'PageName' AND @SortDescending = 1 THEN tblPageLanguage.Name END DESC,
			CASE WHEN @SortColumn = 'PageName' THEN tblPageLanguage.Name END ASC,
			-- Changed By Sorting
			CASE WHEN @SortColumn = 'ChangedBy' AND @SortDescending = 1 THEN tblPageLanguage.ChangedByName END DESC,
			CASE WHEN @SortColumn = 'ChangedBy' THEN tblPageLanguage.ChangedByName END ASC,
			-- External Url Sorting
			CASE WHEN @SortColumn = 'ExternalURL' AND @SortDescending = 1 THEN tblPageLanguage.ExternalURL END DESC,
			CASE WHEN @SortColumn = 'ExternalURL' THEN tblPageLanguage.ExternalURL END ASC,
			-- Language Sorting
			CASE WHEN @SortColumn = 'Language' AND @SortDescending = 1 THEN tblLanguageBranch.LanguageID END DESC,
			CASE WHEN @SortColumn = 'Language' THEN tblLanguageBranch.LanguageID END ASC
		) AS rownum,
		tblPageLanguage.fkPageID, tblPageLanguage.[Version], count(*) over () as totcount
		FROM tblPageLanguage 
		INNER JOIN tblTree ON tblTree.fkChildID=tblPageLanguage.fkPageID 
		INNER JOIN tblPage ON tblPage.pkID=tblPageLanguage.fkPageID 
		INNER JOIN tblPageType ON tblPageType.pkID=tblPage.fkPageTypeID
		INNER JOIN tblLanguageBranch ON tblLanguageBranch.pkID=tblPageLanguage.fkLanguageBranchID 
		WHERE 
        (tblTree.fkParentID=@PageID OR (tblPageLanguage.fkPageID=@PageID AND tblTree.NestingLevel = 1 ))
        AND 
        (tblPageLanguage.ExternalURL IS NOT NULL)
        AND tblPage.ContentType = 0
        AND
        (@Language = -1 OR tblPageLanguage.fkLanguageBranchID = @Language)
	)
	SELECT PageCTE.fkPageID, PageCTE.[Version], PageCTE.rownum, totcount
	FROM PageCTE
	WHERE rownum > @PageSize * (@PageNumber)
	AND rownum <= @PageSize * (@PageNumber+1)
	ORDER BY rownum
END
GO
PRINT N'Altering [dbo].[editSaveContentVersionData]...';


GO
ALTER PROCEDURE [dbo].[editSaveContentVersionData]
(
	@WorkContentID		INT,
	@UserName       NVARCHAR(255),
	@Saved			DATETIME,
	@Name			NVARCHAR(255)	= NULL,
	@ExternalURL	NVARCHAR(255)	= NULL,
	@Created		DATETIME		= NULL,
	@Changed		BIT				= 0,
	@StartPublish	DATETIME		= NULL,
	@StopPublish	DATETIME		= NULL,
	@ChildOrder		INT				= 3,
	@PeerOrder		INT				= 100,
	@ContentLinkGUID   UNIQUEIDENTIFIER				= NULL,
	@LinkURL		NVARCHAR(255)	= NULL,
	@BlobUri		NVARCHAR(255)	= NULL,
	@ThumbnailUri	NVARCHAR(255)	= NULL,
	@LinkType		INT				= 0,
	@FrameID		INT				= NULL,
	@VisibleInMenu	BIT				= NULL,
	@ArchiveContentGUID	UNIQUEIDENTIFIER				= NULL,
	@FolderID		INT				= NULL,
	@ContentAssetsID UNIQUEIDENTIFIER				= NULL ,
	@ContentOwnerID UNIQUEIDENTIFIER				= NULL ,
	@URLSegment		NVARCHAR(255)	= NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @ChangedDate		DATETIME
	DECLARE @ContentID			INT
	DECLARE @ContentTypeID		INT
	DECLARE @ParentID			INT
	DECLARE @ExternalFolderID		INT
	DECLARE @AssetsID			UNIQUEIDENTIFIER
	DECLARE @OwnerID			UNIQUEIDENTIFIER
	DECLARE @CurrentLangBranchID INT
	DECLARE @IsMasterLang		BIT
	
	/* Pull some useful information from the published Content */
	SELECT
		@ContentID				= fkContentID,
		@ParentID			= fkParentID,
		@ContentTypeID			= fkContentTypeID,
		@ExternalFolderID	= ExternalFolderID,
		@AssetsID			= ContentAssetsID,
		@OwnerID			= ContentOwnerID,
		@IsMasterLang		= CASE WHEN tblContent.fkMasterLanguageBranchID=tblWorkContent.fkLanguageBranchID THEN 1 ELSE 0 END,
		@CurrentLangBranchID = fkLanguageBranchID
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
			ChangedByName	= @UserName,
			ContentLinkGUID	= @ContentLinkGUID,
			ArchiveContentGUID	= @ArchiveContentGUID,
			fkFrameID		= @FrameID,
			Name			= @Name,
			LinkURL			= @LinkURL,
			BlobUri			= @BlobUri,
			ThumbnailUri	= @ThumbnailUri,
			ExternalURL		= @ExternalURL,
			URLSegment		= @URLSegment,
			VisibleInMenu	= @VisibleInMenu,
			LinkType		= @LinkType,
			Created			= COALESCE(@Created, Created),
			Saved			= @Saved,
			StartPublish	= @StartPublish,
			StopPublish		= @StopPublish,
			ChildOrderRule	= @ChildOrder,
			PeerOrder		= COALESCE(@PeerOrder, PeerOrder),
			ChangedOnPublish= @Changed
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
				StartPublish	= @StartPublish,
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
					ArchiveContentGUID = @ArchiveContentGUID,
					ChildOrderRule	= @ChildOrder,
					PeerOrder		= @PeerOrder,
					VisibleInMenu	= @VisibleInMenu
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
	@FolderID			INT,
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
		(fkContentTypeID, CreatorName, fkParentID, ExternalFolderID, ContentAssetsID, ContentOwnerID, ContentGUID, ContentPath, ContentType, Deleted)
	VALUES
		(@ContentTypeID, @UserName, @ParentID, @FolderID, @ContentAssetsID, @ContentOwnerID, @ContentGUID, @Path, @ContentType, @Delete)

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
PRINT N'Altering [dbo].[netContentCreateLanguage]...';


GO
ALTER PROCEDURE [dbo].[netContentCreateLanguage]
(
	@ContentID			INT,
	@WorkContentID		INT,
	@UserName NVARCHAR(255),
	@MaxVersions	INT = NULL,
	@SavedDate		DATETIME = NULL,
	@LanguageBranch	NCHAR(17)
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @LangBranchID		INT
	DECLARE @NewVersionID		INT
	
	IF @SavedDate IS NULL
		SET @SavedDate = GetDate()
	
	SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID=@LanguageBranch
	IF @LangBranchID IS NULL
	BEGIN
		RAISERROR (N'netContentCreateLanguage: LanguageBranchID is null, possibly empty table tblLanguageBranch', 16, 1, @WorkContentID)
		RETURN 0
	END

	IF NOT EXISTS( SELECT * FROM tblContentLanguage WHERE fkContentID=@ContentID )
		UPDATE tblContent SET fkMasterLanguageBranchID=@LangBranchID WHERE pkID=@ContentID
	
	INSERT INTO tblContentLanguage(fkContentID, CreatorName, ChangedByName, Status, fkLanguageBranchID)
	SELECT @ContentID, @UserName, @UserName, 2, @LangBranchID
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
		1
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
	SELECT TOP 1 P.pkID as ID, P.fkContentTypeID as ContentTypeID, P.fkParentID as ParentID, P.ContentGUID, PL.LinkURL, P.Deleted, CASE WHEN Status = 4 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS PendingPublish, PL.Created, PL.Changed, PL.Saved, PL.StartPublish, PL.StopPublish, P.ExternalFolderID, P.ContentAssetsID, P.fkMasterLanguageBranchID as MasterLanguageBranchID, PL.ContentLinkGUID as ContentLinkID, PL.AutomaticLink, PL.FetchData, P.ContentType
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
	SELECT TOP 1 P.pkID as ID, P.fkContentTypeID as ContentTypeID, P.fkParentID as ParentID, P.ContentGUID, PL.LinkURL, P.Deleted, CASE WHEN Status = 4 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS PendingPublish, PL.Created, PL.Changed, PL.Saved, PL.StartPublish, PL.StopPublish, P.ExternalFolderID, P.ContentAssetsID, P.fkMasterLanguageBranchID as MasterLanguageBranchID, PL.ContentLinkGUID as ContentLinkID, PL.AutomaticLink, PL.FetchData, P.ContentType
	FROM tblContent AS P WITH (NOLOCK)
	LEFT JOIN tblContentLanguage AS PL ON PL.fkContentID = P.pkID
	WHERE P.pkID = @ContentID AND (P.fkMasterLanguageBranchID = PL.fkLanguageBranchID OR P.fkMasterLanguageBranchID IS NULL)
END
GO
PRINT N'Altering [dbo].[netPersonalNotReadyList]...';


GO
ALTER PROCEDURE [dbo].[netPersonalNotReadyList]
(
    @UserName NVARCHAR(255),
    @Offset INT = 0,
    @Count INT = 50,
    @LanguageBranch NCHAR(17) = NULL
)
AS

BEGIN	
	SET NOCOUNT ON

    DECLARE @LangBranchID NCHAR(17);
	SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID = @LanguageBranch
	IF @LangBranchID IS NULL 
	BEGIN 
		if @LanguageBranch IS NOT NULL
			RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)
		else
			SET @LangBranchID = -1
	END

	DECLARE @InvariantLangBranchID NCHAR(17);
	SELECT @InvariantLangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID = ''

	-- Determine the first record and last record
	DECLARE @FirstRecord int, @LastRecord int

	SELECT @FirstRecord = @Offset
	SELECT @LastRecord = (@Offset + @Count + 1);

	WITH TempResult as
	(
		SELECT	ROW_NUMBER() OVER(ORDER BY W.Saved DESC) as RowNumber,
			W.fkContentID AS ContentID,
			W.pkID AS WorkID,
			2 AS VersionStatus,
			W.ChangedByName AS UserName,
			W.Saved AS ItemCreated,
			W.Name,
			W.fkLanguageBranchID as LanguageBranch,
			W.CommonDraft,
			W.fkMasterVersionID as MasterVersion,
			CASE WHEN C.fkMasterLanguageBranchID=W.fkLanguageBranchID THEN 1 ELSE 0 END AS IsMasterLanguageBranch
		FROM
			tblWorkContent AS W
		INNER JOIN
			tblContent AS C ON C.pkID=W.fkContentID
		WHERE
			W.ChangedByName=@UserName AND
			W.Status = 2 AND
			C.Deleted=0 AND
            (@LanguageBranch = NULL OR 
			W.fkLanguageBranchID = @LangBranchID OR
			W.fkLanguageBranchID = @InvariantLangBranchID)
	)
	SELECT  TOP (@LastRecord - 1) *
	FROM    TempResult
	WHERE   RowNumber > @FirstRecord AND
		  RowNumber < @LastRecord
   		
END
GO
PRINT N'Altering [dbo].[netPersonalRejectedList]...';


GO
ALTER PROCEDURE [dbo].[netPersonalRejectedList]
(
	@UserName NVARCHAR(255),
    @Offset INT = 0,
    @Count INT = 50,
    @LanguageBranch NCHAR(17) = NULL
)
AS
BEGIN
	SET NOCOUNT ON

    DECLARE @LangBranchID NCHAR(17);
	SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID = @LanguageBranch
	IF @LangBranchID IS NULL 
	BEGIN 
		if @LanguageBranch IS NOT NULL
			RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)
		else
			SET @LangBranchID = -1
	END

	
	DECLARE @InvariantLangBranchID NCHAR(17);
	SELECT @InvariantLangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID = ''

	-- Determine the first record and last record
	DECLARE @FirstRecord int, @LastRecord int

	SELECT @FirstRecord = @Offset
	SELECT @LastRecord = (@Offset + @Count + 1);


	WITH TempResult as
	(
		SELECT	ROW_NUMBER() OVER(ORDER BY W.Saved DESC) as RowNumber,
			W.fkContentID AS ContentID,
			W.pkID AS WorkID,
			1 AS VersionStatus,
			W.ChangedByName AS UserName,
			W.Saved AS ItemCreated,
			W.Name,
			W.fkLanguageBranchID as LanguageBranch,
			W.CommonDraft,
			W.fkMasterVersionID as MasterVersion,
			CASE WHEN C.fkMasterLanguageBranchID=W.fkLanguageBranchID THEN 1 ELSE 0 END AS IsMasterLanguageBranch
		FROM
			tblWorkContent AS W
		INNER JOIN
			tblContent AS C ON C.pkID=W.fkContentID
		WHERE
			W.ChangedByName=@UserName AND
			W.Status = 1 AND
			C.Deleted=0 AND
			(@LanguageBranch = NULL OR 
			W.fkLanguageBranchID = @LangBranchID OR
			W.fkLanguageBranchID = @InvariantLangBranchID)
	)
	SELECT  TOP (@LastRecord - 1) *
	FROM    TempResult
	WHERE   RowNumber > @FirstRecord AND
		  RowNumber < @LastRecord
   		
END
GO
PRINT N'Altering [dbo].[netReadyToPublishList]...';


GO
ALTER PROCEDURE [dbo].[netReadyToPublishList]
(
    @Offset INT = 0,
    @Count INT = 50,
    @LanguageBranch NCHAR(17) = NULL
)
AS
BEGIN
	SET NOCOUNT ON

    DECLARE @LangBranchID NCHAR(17);
	SELECT @LangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID = @LanguageBranch
	IF @LangBranchID IS NULL 
	BEGIN 
		if @LanguageBranch IS NOT NULL
			RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)
		else
			SET @LangBranchID = -1
	END

	DECLARE @InvariantLangBranchID NCHAR(17);
	SELECT @InvariantLangBranchID = pkID FROM tblLanguageBranch WHERE LanguageID = ''

	-- Determine the first record and last record
	DECLARE @FirstRecord int, @LastRecord int

	SELECT @FirstRecord = @Offset
	SELECT @LastRecord = (@Offset + @Count + 1);


	WITH TempResult as
	(
		SELECT	ROW_NUMBER() OVER(ORDER BY W.Saved DESC) as RowNumber,
			W.fkContentID AS ContentID,
			W.pkID AS WorkID,
			3 AS VersionStatus,
			W.ChangedByName AS UserName,
			W.Saved AS ItemCreated,
			W.Name,
			W.fkLanguageBranchID as LanguageBranch,
			W.CommonDraft,
			W.fkMasterVersionID as MasterVersion,
			CASE WHEN C.fkMasterLanguageBranchID=W.fkLanguageBranchID THEN 1 ELSE 0 END AS IsMasterLanguageBranch
		FROM
			tblWorkContent AS W
		INNER JOIN
			tblContent AS C ON C.pkID=W.fkContentID
		WHERE
			W.Status = 3 AND
			C.Deleted=0 AND
			(@LanguageBranch = NULL OR 
			W.fkLanguageBranchID = @LangBranchID OR
			W.fkLanguageBranchID = @InvariantLangBranchID)
	)
	SELECT  TOP (@LastRecord - 1) *
	FROM    TempResult
	WHERE   RowNumber > @FirstRecord AND
		  RowNumber < @LastRecord
   		
END
GO
PRINT N'Altering [dbo].[editSetCommonDraftVersion]...';


GO
ALTER PROCEDURE [dbo].[editSetCommonDraftVersion]
(
	@WorkContentID INT,
	@Force BIT
)
AS
BEGIN
   SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE  @ContentLink INT
	DECLARE  @LangID INT
	DECLARE  @CommonDraft INT
	
	-- Find the ConntentLink and Language for the Page Work ID 
	SELECT   @ContentLink = fkContentID, @LangID = fkLanguageBranchID, @CommonDraft = CommonDraft from tblWorkContent where pkID = @WorkContentID
	
	
	-- If the force flag or there is a common draft which is published we will reset the common draft
	if (@Force = 1 OR EXISTS(SELECT * FROM tblWorkContent WITH(NOLOCK) WHERE fkContentID = @ContentLink AND Status=4 AND fkLanguageBranchID = @LangID AND CommonDraft = 1))
	BEGIN 	
		-- We should remove the old common draft from other content version repect to language
		UPDATE 
			tblWorkContent
		SET
			CommonDraft = 0
		FROM  tblWorkContent WITH(INDEX(IDX_tblWorkContent_fkContentID))
		WHERE
			fkContentID = @ContentLink and fkLanguageBranchID  = @LangID  
	END
	-- If the forct flag or there is no common draft for the page wirh respect to language
	IF (@Force = 1 OR NOT EXISTS(SELECT * from tblWorkContent WITH(NOLOCK)  where fkContentID = @ContentLink AND fkLanguageBranchID = @LangID AND CommonDraft = 1))
	BEGIN
		UPDATE 
			tblWorkContent
		SET
			CommonDraft = 1
		WHERE
			pkID = @WorkContentID
	END	
		
	IF (@@ROWCOUNT = 0)
		RETURN 1

	RETURN 0
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
		StartPublish
	FROM
		tblWorkContent
	WHERE
		Status = 6 AND
		StartPublish <= @UntilDate AND
		(fkContentID = @ContentID OR @ContentID IS NULL)
	ORDER BY
		StartPublish
END
GO
PRINT N'Altering [dbo].[netUnifiedPathDeleteAll]...';


GO
ALTER PROCEDURE dbo.netUnifiedPathDeleteAll
AS
BEGIN
	DELETE FROM tblUnifiedPathAcl
	WHERE fkUnifiedPathID IN (SELECT pkID FROM tblUnifiedPath)

	DELETE FROM tblUnifiedPathProperty
	WHERE fkUnifiedPathID IN (SELECT pkID FROM tblUnifiedPath)

	DELETE FROM tblUnifiedPath
END
GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7007
GO
PRINT N'Creating [dbo].[editSetVersionStatus]...';


GO
CREATE PROCEDURE [dbo].[editSetVersionStatus]
(
	@WorkContentID INT,
	@Status INT,
	@UserName NVARCHAR(255),
	@Saved DATETIME = NULL,
	@RejectComment NVARCHAR(2000) = NULL
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
		Saved = COALESCE(@Saved, Saved)
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
				Status = @Status
			WHERE
				fkContentID=@ContentID AND fkLanguageBranchID=@LanguageBranchID

		END

	RETURN 0
END
GO
PRINT N'Creating [dbo].[netContentDataLoad]...';


GO
CREATE PROCEDURE [dbo].[netContentDataLoad]
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
		L.Status as PageWorkStatus
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
PRINT N'Creating [dbo].[netContentListPaged]...';


GO
CREATE PROCEDURE dbo.netContentListPaged
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
		L.fkLanguageBranchID AS PageLanguageBranchID
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
PRINT N'Creating [dbo].[netContentListVersionsPaged]...';


GO
CREATE PROCEDURE dbo.netContentListVersionsPaged
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
		W.fkLanguageBranchID AS PageLanguageBranchID
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
PRINT N'Creating [dbo].[netContentLoadVersion]...';


GO
CREATE PROCEDURE dbo.netContentLoadVersion
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
		W.fkLanguageBranchID AS PageLanguageBranchID
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
PRINT N'Altering [dbo].[editCreateContentVersion]...';


GO
ALTER PROCEDURE [dbo].[editCreateContentVersion]
(
	@ContentID			INT,
	@WorkContentID		INT,
	@UserName		NVARCHAR(255),
	@MaxVersions	INT = NULL,
	@SavedDate		DATETIME = NULL,
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
	
	IF @SavedDate IS NULL
		SET @SavedDate = GetDate()
	
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
	

	/* Set NewWorkContentID as Common draft version if there is no common draft or the common draft is the published version */
	EXEC editSetCommonDraftVersion @WorkContentID = @NewWorkContentID, @Force = 0			
	
	RETURN @NewWorkContentID
END
GO
PRINT N'Altering [dbo].[netContentEnsureVersions]...';


GO
ALTER PROCEDURE dbo.netContentEnsureVersions
(
	@ContentID			INT
)
AS
BEGIN

	DECLARE @LangBranchID INT
	DECLARE @LanguageBranch NCHAR(17)
	DECLARE @NewWorkContentID INT
	DECLARE @UserName NVARCHAR(255)

	CREATE TABLE #ContentLangsWithoutVersion
		(fkLanguageBranchID INT)

	/* Get a list of page languages that do not have an entry in tblWorkContent for the given page */
	INSERT INTO #ContentLangsWithoutVersion
		(fkLanguageBranchID)
	SELECT 
		tblContentLanguage.fkLanguageBranchID
	FROM 
		tblContentLanguage
	WHERE	
		fkContentID=@ContentID AND
		NOT EXISTS(
			SELECT * 
			FROM 
				tblWorkContent 
			WHERE 
				tblWorkContent.fkContentID=tblContentLanguage.fkContentID AND 
				tblWorkContent.fkLanguageBranchID=tblContentLanguage.fkLanguageBranchID)

	/* Get the first language to create a page version for */
	SELECT 
		@LangBranchID=Min(fkLanguageBranchID) 
	FROM 
		#ContentLangsWithoutVersion

	WHILE NOT @LangBranchID IS NULL
	BEGIN

		/* Get language name and user name to set for page version that we are about to create */
		SELECT 
			@LanguageBranch=LanguageID 
		FROM 
			tblLanguageBranch 
		WHERE 
			pkID=@LangBranchID
		SELECT 
			@UserName=ChangedByName 
		FROM 
			tblContentLanguage 
		WHERE 
			fkContentID=@ContentID AND 
			fkLanguageBranchID=@LangBranchID

		/* Create a new page version for the given page and language */
		EXEC @NewWorkContentID = editCreateContentVersion 
			@ContentID=@ContentID, 
			@WorkContentID=NULL, 
			@UserName=@UserName,
			@LanguageBranch=@LanguageBranch

		/* TODO - check if we should mark page version as published... */
		UPDATE 
			tblWorkContent 
		SET 
			Status = 5
		WHERE 
			pkID=@NewWorkContentID
		UPDATE 
			tblContentLanguage 
		SET 
			[Version]=@NewWorkContentID 
		WHERE 
			fkContentID=@ContentID AND 
			fkLanguageBranchID=@LangBranchID

		/* Get next language for the loop */
		SELECT 
			@LangBranchID=Min(fkLanguageBranchID) 
		FROM 
			#ContentLangsWithoutVersion 
		WHERE 
			fkLanguageBranchID > @LangBranchID
	END

	DROP TABLE #ContentLangsWithoutVersion
END
GO
PRINT N'Altering [dbo].[editDeletePageVersion]...';


GO
ALTER PROCEDURE dbo.editDeletePageVersion
(
	@WorkPageID		INT
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @PageID				INT
	DECLARE @PublishedWorkID	INT
	DECLARE @LangBranchID		INT
	
	/* Verify that we can delete this version (i e do not allow removal of current version) */
	SELECT 
		@PageID=tblPageLanguage.fkPageID, 
		@LangBranchID=tblPageLanguage.fkLanguageBranchID,
		@PublishedWorkID=tblPageLanguage.[Version] 
	FROM 
		tblWorkPage 
	INNER JOIN 
		tblPageLanguage ON tblPageLanguage.fkPageID=tblWorkPage.fkPageID AND tblPageLanguage.fkLanguageBranchID = tblWorkPage.fkLanguageBranchID
	WHERE 
		tblWorkPage.pkID=@WorkPageID
		
	IF (@@ROWCOUNT <> 1 OR @PublishedWorkID=@WorkPageID)
		RETURN -1
	IF ( (SELECT COUNT(pkID) FROM tblWorkPage WHERE fkPageID=@PageID AND fkLanguageBranchID=@LangBranchID ) < 2 )
		RETURN -1
		
	EXEC editDeletePageVersionInternal @WorkPageID=@WorkPageID
	
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
		CASE WHEN tblContent.fkMasterLanguageBranchID=P.fkLanguageBranchID THEN 1 ELSE 0 END AS IsMasterLanguageBranch
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
				EXEC @retval=editDeletePageVersion @WorkPageID=@DeleteWorkContentID
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
	DECLARE @StartPublish DATETIME

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
			ChangedByName = W.ChangedByName,
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
			@StartPublish = StartPublish	= COALESCE(W.StartPublish, tblContentLanguage.StartPublish, DATEADD(s, -30, @PublishedDate)),
			StopPublish		= W.StopPublish,
			Status  = 4,
			Version= @WorkContentID
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

	/* Remember that this version has been published, and get the publish dates back into tblWorkContent */
	UPDATE
		tblWorkContent
	SET
		Status = 4,
		ChangedOnPublish = 0,
		StartPublish=@StartPublish,
		Saved=@PublishedDate,
		NewStatusByName=@UserName,
		fkMasterVersionID = NULL
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

ALTER PROCEDURE [dbo].[netReportPublishedPages](
	@PageID int,
	@StartDate datetime,
	@StopDate datetime,
	@Language int = -1,
	@ChangedByUserName nvarchar(256) = null,
	@PageSize int,
	@PageNumber int = 0,
	@SortColumn varchar(40) = 'StartPublish',
	@SortDescending bit = 0
)
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
		tblPageLanguage.fkPageID, tblPageLanguage.Version AS PublishedVersion, count(*) over () as totcount
		FROM tblPageLanguage 
		INNER JOIN tblTree ON tblTree.fkChildID=tblPageLanguage.fkPageID 
		INNER JOIN tblPage ON tblPage.pkID=tblPageLanguage.fkPageID 
		INNER JOIN tblPageType ON tblPageType.pkID=tblPage.fkPageTypeID 
		INNER JOIN tblLanguageBranch ON tblLanguageBranch.pkID=tblPageLanguage.fkLanguageBranchID
		WHERE
		(tblTree.fkParentID=@PageID OR (tblPageLanguage.fkPageID=@PageID AND tblTree.NestingLevel = 1 ))
        AND tblPage.ContentType = 0
		AND tblPageLanguage.Status=4
		AND 
		(@StartDate IS NULL OR tblPageLanguage.StartPublish>@StartDate)
		AND
		(@StopDate IS NULL OR tblPageLanguage.StartPublish<@StopDate)
		AND
		(@Language = -1 OR tblPageLanguage.fkLanguageBranchID = @Language)
		AND
		(@ChangedByUserName IS NULL OR tblPageLanguage.ChangedByName = @ChangedByUserName)
	)
	SELECT PageCTE.fkPageID, PageCTE.PublishedVersion, PageCTE.rownum, totcount
	FROM PageCTE
	WHERE rownum > @PageSize * (@PageNumber)
	AND rownum <= @PageSize * (@PageNumber+1)
	ORDER BY rownum'

	EXEC sp_executesql @sql, N'@PageID int, @StartDate datetime, @StopDate datetime, @Language int, @ChangedByUserName nvarchar(256), @PageSize int, @PageNumber int',
		@PageID = @PageID, 
		@StartDate = @StartDate, 
		@StopDate = @StopDate, 
		@Language = @Language, 
		@ChangedByUserName = @ChangedByUserName, 
		@PageSize = @PageSize, 
		@PageNumber = @PageNumber
	
END
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
	@PublishedByName nvarchar(256) = null
)
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
        AND tblPage.ContentType = 0
		AND tblPageLanguage.Status=4
		AND
		(LEN(@PublishedByName) = 0 OR tblPageLanguage.ChangedByName = @PublishedByName)
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
ALTER PROCEDURE [dbo].[netReportChangedPages](
	@PageID int,
	@StartDate datetime,
	@StopDate datetime,
	@Language int = -1,
	@ChangedByUserName nvarchar(256) = null,
	@PageSize int,
	@PageNumber int = 0,
	@SortColumn varchar(40) = 'Saved',
	@SortDescending bit = 0
)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @OrderBy NVARCHAR(MAX)
	SET @OrderBy =
		CASE @SortColumn
			WHEN 'PageName' THEN 'tblPageLanguage.Name'
			WHEN 'ChangedBy' THEN 'tblPageLanguage.ChangedByName'
			WHEN 'Saved' THEN 'tblPageLanguage.Saved'
			WHEN 'Language' THEN 'tblLanguageBranch.LanguageID'
			WHEN 'PageTypeName' THEN 'tblPageType.Name'
		END
	IF(@SortDescending = 1)
		SET @OrderBy = @OrderBy + ' DESC'
		
	DECLARE @sql NVARCHAR(MAX)
	Set @sql = 'WITH PageCTE AS
	(
		SELECT ROW_NUMBER() OVER(ORDER BY '
			+ @OrderBy
			+ ') AS rownum,
		tblPageLanguage.fkPageID, tblPageLanguage.Version AS PublishedVersion, count(*) over () as totcount
		FROM tblPageLanguage 
		INNER JOIN tblTree ON tblTree.fkChildID=tblPageLanguage.fkPageID 
		INNER JOIN tblPage ON tblPage.pkID=tblPageLanguage.fkPageID 
		INNER JOIN tblPageType ON tblPageType.pkID=tblPage.fkPageTypeID 
		INNER JOIN tblLanguageBranch ON tblLanguageBranch.pkID=tblPageLanguage.fkLanguageBranchID 
		WHERE (tblTree.fkParentID=@PageID OR (tblPageLanguage.fkPageID=@PageID AND tblTree.NestingLevel = 1 ))
        AND (@StartDate IS NULL OR tblPageLanguage.Saved>@StartDate)
        AND (@StopDate IS NULL OR tblPageLanguage.Saved<@StopDate)
        AND (@Language = -1 OR tblPageLanguage.fkLanguageBranchID = @Language)
        AND (@ChangedByUserName IS NULL OR tblPageLanguage.ChangedByName = @ChangedByUserName)
        AND (@ChangedByUserName IS NULL OR tblPageLanguage.ChangedByName = @ChangedByUserName)
        AND tblPage.ContentType = 0
        AND tblPageLanguage.Status=4
	)
	SELECT PageCTE.fkPageID, PageCTE.PublishedVersion, PageCTE.rownum, totcount
	FROM PageCTE
	WHERE rownum > @PageSize * (@PageNumber)
	AND rownum <= @PageSize * (@PageNumber+1)
	ORDER BY rownum'
	
	EXEC sp_executesql @sql, N'@PageID int, @StartDate datetime, @StopDate datetime, @Language int, @ChangedByUserName nvarchar(256), @PageSize int, @PageNumber int',
		@PageID = @PageID, 
		@StartDate = @StartDate, 
		@StopDate = @StopDate, 
		@Language = @Language, 
		@ChangedByUserName = @ChangedByUserName, 
		@PageSize = @PageSize, 
		@PageNumber = @PageNumber
END
GO
ALTER PROCEDURE dbo.netPropertySearch
(
	@PageID			INT,
	@FindProperty	NVARCHAR(255),
	@NotProperty	NVARCHAR(255),
	@LanguageBranch	NCHAR(17) = NULL
)
AS
BEGIN
	DECLARE @LangBranchID NCHAR(17);
	SELECT @LangBranchID=pkID FROM tblLanguageBranch WHERE LanguageID=@LanguageBranch
	IF @LangBranchID IS NULL 
	BEGIN 
		if @LanguageBranch IS NOT NULL
			RAISERROR('Language branch %s is not defined',16,1, @LanguageBranch)
		else
			SET @LangBranchID = -1
	END
		
	SET NOCOUNT ON
	/* All levels */
	SELECT
		tblPage.pkID
	FROM 
		tblPage
	INNER JOIN
		tblTree ON tblTree.fkChildID=tblPage.pkID
	INNER JOIN
		tblPageType ON tblPage.fkPageTypeID=tblPageType.pkID
	INNER JOIN
		tblPageDefinition ON tblPageType.pkID=tblPageDefinition.fkPageTypeID 
		AND tblPageDefinition.Name=@FindProperty
	INNER JOIN
		tblProperty ON tblProperty.fkPageID=tblPage.pkID 
		AND tblPageDefinition.pkID=tblProperty.fkPageDefinitionID
	INNER JOIN 
		tblPageLanguage ON tblPageLanguage.fkPageID=tblPage.pkID
	WHERE
		tblPageType.ContentType = 0 AND
		tblTree.fkParentID=@PageID AND
		tblPage.Deleted = 0 AND
		tblPageLanguage.[Status] = 4 AND
		(@LangBranchID=-1 OR tblPageLanguage.fkLanguageBranchID=@LangBranchID OR tblPageDefinition.LanguageSpecific<3) AND
		(@NotProperty IS NULL OR NOT EXISTS(
			SELECT * FROM tblProperty 
			INNER JOIN tblPageDefinition ON tblPageDefinition.pkID=tblProperty.fkPageDefinitionID 
			WHERE tblPageDefinition.Name=@NotProperty 
			AND tblProperty.fkPageID=tblPage.pkID))
	ORDER BY tblPageLanguage.Name ASC
END
GO
ALTER PROCEDURE dbo.netQuickSearchByExternalUrl
(
	@Url	NVARCHAR(255)
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
		tblPageLanguage.StartPublish <= GetDate() AND
		(tblPageLanguage.StopPublish IS NULL OR tblPageLanguage.StopPublish >= GetDate())
	ORDER BY
		tblPageLanguage.Changed DESC
END
GO

PRINT N'Refreshing [dbo].[editDeletePageCheckInternal]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeletePageCheckInternal]';


GO
PRINT N'Refreshing [dbo].[netConvertPropertyForPageType]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netConvertPropertyForPageType]';


GO
PRINT N'Refreshing [dbo].[netFrameDelete]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netFrameDelete]';


GO
PRINT N'Refreshing [dbo].[netPageListByLanguage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageListByLanguage]';


GO
PRINT N'Refreshing [dbo].[netPagesChangedAfter]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPagesChangedAfter]';


GO
PRINT N'Refreshing [dbo].[netPageTypeGetUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageTypeGetUsage]';


GO
PRINT N'Refreshing [dbo].[netPropertySearch]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertySearch]';


GO
PRINT N'Refreshing [dbo].[netPropertySearchCategory]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertySearchCategory]';


GO
PRINT N'Refreshing [dbo].[netPropertySearchNull]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertySearchNull]';


GO
PRINT N'Refreshing [dbo].[netPropertySearchString]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertySearchString]';


GO
PRINT N'Refreshing [dbo].[netPropertySearchValue]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertySearchValue]';


GO
PRINT N'Refreshing [dbo].[netQuickSearchByExternalUrl]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netQuickSearchByExternalUrl]';


GO
PRINT N'Refreshing [dbo].[netQuickSearchByPath]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netQuickSearchByPath]';


GO
PRINT N'Refreshing [dbo].[netURLSegmentListPages]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netURLSegmentListPages]';


GO
PRINT N'Refreshing [dbo].[netURLSegmentSet]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netURLSegmentSet]';


GO
PRINT N'Refreshing [dbo].[editDeleteChildsCheck]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeleteChildsCheck]';


GO
PRINT N'Refreshing [dbo].[editDeletePageCheck]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeletePageCheck]';


GO
PRINT N'Refreshing [dbo].[editDeleteChilds]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeleteChilds]';


GO
PRINT N'Refreshing [dbo].[editDeletePage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeletePage]';


GO
PRINT N'Refreshing [dbo].[netContentChildrenReferences]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netContentChildrenReferences]';


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
PRINT N'Refreshing [dbo].[netPropertyDefinitionGetUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertyDefinitionGetUsage]';


GO
PRINT N'Refreshing [dbo].[netPropertySearchCategoryMeta]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertySearchCategoryMeta]';


GO
PRINT N'Refreshing [dbo].[netSoftLinkList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netSoftLinkList]';


GO
PRINT N'Refreshing [dbo].[admDatabaseStatistics]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[admDatabaseStatistics]';


GO
PRINT N'Refreshing [dbo].[netConvertPageType]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netConvertPageType]';


GO
PRINT N'Refreshing [dbo].[netCreatePath]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netCreatePath]';


GO
PRINT N'Refreshing [dbo].[netDynamicPropertiesLoad]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netDynamicPropertiesLoad]';


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
PRINT N'Refreshing [dbo].[netPageListAll]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageListAll]';


GO
PRINT N'Refreshing [dbo].[netPageListExternalFolderID]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageListExternalFolderID]';


GO
PRINT N'Refreshing [dbo].[netPageMaxFolderId]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageMaxFolderId]';


GO
PRINT N'Refreshing [dbo].[netPagePath]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPagePath]';


GO
PRINT N'Refreshing [dbo].[netPageTypeCheckUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPageTypeCheckUsage]';


GO
PRINT N'Refreshing [dbo].[netPersonalActivityList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPersonalActivityList]';


GO
PRINT N'Refreshing [dbo].[netQuickSearchByFolderID]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netQuickSearchByFolderID]';


GO
PRINT N'Refreshing [dbo].[netQuickSearchListFolderID]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netQuickSearchListFolderID]';


GO
PRINT N'Refreshing [dbo].[netReportReadyToPublish]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netReportReadyToPublish]';


GO
PRINT N'Refreshing [dbo].[netSubscriptionListRoots]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netSubscriptionListRoots]';


GO
PRINT N'Refreshing [dbo].[netBlockTypeGetUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netBlockTypeGetUsage]';


GO
PRINT N'Refreshing [dbo].[netContentListBlobUri]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netContentListBlobUri]';


GO
PRINT N'Refreshing [dbo].[netPropertyDefinitionCheckUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netPropertyDefinitionCheckUsage]';


GO
PRINT N'Refreshing [dbo].[netBlockTypeCheckUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[netBlockTypeCheckUsage]';


GO
PRINT N'Refreshing [dbo].[editDeletePageVersionInternal]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editDeletePageVersionInternal]';


GO

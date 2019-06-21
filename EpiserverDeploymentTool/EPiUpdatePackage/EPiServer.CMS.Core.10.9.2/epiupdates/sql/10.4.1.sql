--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7042)
				select 0, 'Already correct database version'
            else if (@ver = 7041)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
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
			fkLanguageBranchID,
			URLSegment,
			ThumbnailUri,
			BlobUri)
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
			URLSegment,
			ThumbnailUri,
			BlobUri
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
				URLSegment,
				ThumbnailUri,
				BlobUri)
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
				tblContentLanguage.URLSegment,
				ThumbnailUri,
				BlobUri
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
PRINT N'Altering [dbo].[netVersionFilterList]...';

GO
ALTER PROCEDURE [dbo].[netVersionFilterList]
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
	--Optimized for contentid with and without language, those are most used
	IF (@ContentID IS NOT NULL AND @ChangedBy IS NULL AND @ExcludeDeleted = 0 AND @StatusCount = 0)
		IF (@LanguageCount = 0)
		BEGIN
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
					W.fkContentID=@ContentID
			)
			SELECT  ContentID, WorkID, VersionStatus, SavedBy, ItemCreated, Name, LanguageBranchID, CommonDraft, MasterVersion, IsMasterLanguageBranch, StatusChangedBy, DelayPublishUntil, (SELECT COUNT(*) FROM TempResult) AS 'TotalRows'
				FROM    TempResult
				WHERE RowNumber BETWEEN (@StartIndex +1) AND (@MaxRows + @StartIndex)
		END
		ELSE
		BEGIN
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
					W.fkContentID=@ContentID AND
				    W.fkLanguageBranchID IN (SELECT ID FROM @LanguageIds)

		)
		SELECT  ContentID, WorkID, VersionStatus, SavedBy, ItemCreated, Name, LanguageBranchID, CommonDraft, MasterVersion, IsMasterLanguageBranch, StatusChangedBy, DelayPublishUntil, (SELECT COUNT(*) FROM TempResult) AS 'TotalRows'
				FROM    TempResult
				WHERE RowNumber BETWEEN (@StartIndex +1) AND (@MaxRows + @StartIndex)
		END
	ELSE
		DECLARE @SqlQuery NVARCHAR(MAX) = '
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
			WHERE' + CHAR(13);

		DECLARE @IncludeAnd BIT = 0
		IF @ContentID IS NOT NULL
		BEGIN
			SET @SqlQuery += 'W.fkContentID=@ContentID' + CHAR(13);
			SET @IncludeAnd = 1
		END
		IF @ChangedBy IS NOT NULL
		BEGIN
			IF @IncludeAnd = 1
				SET @SqlQuery += 'AND W.ChangedByName=@ChangedBy' + CHAR(13);
			ELSE
				SET @SqlQuery += 'W.ChangedByName=@ChangedBy' + CHAR(13);
			SET @IncludeAnd = 1
		END
		IF @StatusCount > 0
		BEGIN
			IF @IncludeAnd = 1
				SET @SqlQuery += 'AND W.Status IN (SELECT ID FROM @Statuses)' + CHAR(13);
			ELSE
				SET @SqlQuery += 'W.Status IN (SELECT ID FROM @Statuses)' + CHAR(13);
			SET @IncludeAnd = 1
		END
		IF @LanguageCount > 0
		BEGIN
			IF @IncludeAnd = 1
				SET @SqlQuery += 'AND W.fkLanguageBranchID IN (SELECT ID FROM @LanguageIds)' + CHAR(13);
			ELSE
				SET @SqlQuery += 'W.fkLanguageBranchID IN (SELECT ID FROM @LanguageIds)' + CHAR(13);
			SET @IncludeAnd = 1
		END
		IF @ExcludeDeleted = 1
		BEGIN
			IF @IncludeAnd = 1
				SET @SqlQuery += 'AND C.Deleted = 0' + CHAR(13);
			ELSE
				SET @SqlQuery += 'C.Deleted = 0' + CHAR(13);
		END
		SET @SqlQuery += ')' + CHAR(13);
		SET @SqlQuery += 'SELECT  ContentID, WorkID, VersionStatus, SavedBy, ItemCreated, Name, LanguageBranchID, CommonDraft, MasterVersion, IsMasterLanguageBranch, StatusChangedBy, DelayPublishUntil, (SELECT COUNT(*) FROM TempResult) AS ''TotalRows''
			FROM    TempResult
			WHERE RowNumber BETWEEN (@StartIndex +1) AND (@MaxRows + @StartIndex)'
   		
		EXEC sp_executesql @SqlQuery, N'@StartIndex INT, @MaxRows INT, @ContentID INT, @ChangedBy NVARCHAR(255), @Statuses dbo.IDTable READONLY, @LanguageIds dbo.IDTable READONLY, @ExcludeDeleted BIT', 
			@StartIndex = @StartIndex, @MaxRows = @MaxRows, @ContentID = @ContentID, @ChangedBy = @ChangedBy, @Statuses = @Statuses, @LanguageIds = @LanguageIds, @ExcludeDeleted = @ExcludeDeleted
END
GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7042
GO

PRINT N'Update complete.';
GO

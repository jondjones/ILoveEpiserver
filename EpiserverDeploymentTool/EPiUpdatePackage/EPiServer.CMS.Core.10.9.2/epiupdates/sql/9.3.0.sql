--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7028)
				select 0, 'Already correct database version'
            else if (@ver = 7027)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO

PRINT N'Altering [dbo].[netProjectItemSave]...';
GO

ALTER PROCEDURE [dbo].[netProjectItemSave]
	@ProjectItems dbo.ProjectItemTable READONLY
AS
BEGIN
	SET NOCOUNT ON

	IF (SELECT COUNT(*) FROM tblProjectItem tbl JOIN @ProjectItems items ON tbl.pkID = items.ID AND tbl.fkProjectID != items.ProjectID) > 0
		RAISERROR('Not allowed to change ProjectId', 16, 1)
	ELSE
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

PRINT N'Altering [dbo].[netActivityLogAssociationDelete]...';
GO

ALTER PROCEDURE [dbo].[netActivityLogAssociationDelete]
(
	@AssociatedItem	[nvarchar](255),
	@ChangeLogID  BIGINT = 0
)
AS            
BEGIN
	DELETE FROM [tblActivityLogAssociation] WHERE [From] = @AssociatedItem AND (@ChangeLogID = 0 OR @ChangeLogID = [To])
	DECLARE @RowCount INT = (SELECT @@ROWCOUNT)
	UPDATE [tblActivityLog] SET RelatedItem = NULL WHERE @ChangeLogID = 0 AND RelatedItem = @AssociatedItem
	SELECT @@ROWCOUNT + @RowCount
END
GO

GO
PRINT N'Creating [dbo].[tblContentType].[IDX_tblContentType_ContentTypeGUID]...';
GO

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name='IDX_tblContentType_ContentTypeGUID' AND object_id = OBJECT_ID('tblContentType'))
BEGIN
	CREATE UNIQUE NONCLUSTERED INDEX [IDX_tblContentType_ContentTypeGUID] ON [dbo].[tblContentType]([ContentTypeGUID] ASC);
END

GO
PRINT N'Creating [dbo].[tblContentType].[IDX_tblContentType_Name]...';


GO
CREATE UNIQUE NONCLUSTERED INDEX [IDX_tblContentType_Name]
    ON [dbo].[tblContentType]([Name] ASC);


GO
PRINT N'Creating [dbo].[tblPropertyDefinition].[IDX_tblPropertyDefinition_ContentTypeAndName]...';


GO
CREATE UNIQUE NONCLUSTERED INDEX [IDX_tblPropertyDefinition_ContentTypeAndName]
    ON [dbo].[tblPropertyDefinition]([fkContentTypeID] ASC, [Name] ASC);


GO
PRINT N'Altering [dbo].[netContentTypeSave]...';


GO
ALTER PROCEDURE [dbo].[netContentTypeSave]
(
	@ContentTypeID			INT,
	@ContentTypeGUID		UNIQUEIDENTIFIER,
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
	SET XACT_ABORT ON

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
			@ContentTypeGUID,
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
				ContentType = @ContentType,
				@ContentTypeGUID = ContentTypeGUID
			WHERE
				pkID=@ContentTypeID
		END
	END

	IF (@DefaultID IS NULL)
	BEGIN
		DELETE FROM tblContentTypeDefault WHERE fkContentTypeID=@ContentTypeID
	END
	ELSE
	BEGIN
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
	END
		
	SELECT @ContentTypeID AS "ID", @ContentTypeGUID AS "GUID"
END
GO
PRINT N'Altering [dbo].[netPageDefinitionSave]...';


GO
ALTER PROCEDURE dbo.netPageDefinitionSave
(
	@PageDefinitionID      INT OUTPUT,
	@PageTypeID            INT,
	@Name                  NVARCHAR(100),
	@PageDefinitionTypeID  INT,
	@Required              BIT = NULL,
	@Advanced              INT = NULL,
	@Searchable            BIT = NULL,
	@DefaultValueType      INT = NULL,
	@EditCaption           NVARCHAR(255) = NULL,
	@HelpText              NVARCHAR(2000) = NULL,
	@ObjectProgID          NVARCHAR(255) = NULL,
	@LongStringSettings    INT = NULL,
	@SettingsID            UNIQUEIDENTIFIER = NULL,
	@FieldOrder            INT = NULL,
	@Type                  INT = NULL OUTPUT,
	@OldType               INT = NULL OUTPUT,
	@LanguageSpecific      INT = 0,
	@DisplayEditUI         BIT = NULL,
	@ExistsOnModel         BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @OldType = tblPageDefinitionType.Property 
	FROM tblPageDefinition
	INNER JOIN tblPageDefinitionType ON tblPageDefinitionType.pkID=tblPageDefinition.fkPageDefinitionTypeID
	WHERE tblPageDefinition.pkID=@PageDefinitionID

	SELECT @Type = Property FROM tblPageDefinitionType WHERE pkID=@PageDefinitionTypeID
	IF @Type IS NULL
		RAISERROR('Cannot find data type',16,1)
	IF @PageTypeID=0
		SET @PageTypeID = NULL

	IF @PageDefinitionID = 0 AND @ExistsOnModel = 1
	BEGIN
		SET @PageDefinitionID = ISNULL((SELECT pkID FROM tblPageDefinition where Name = @Name AND fkPageTypeID = @PageTypeID), @PageDefinitionID)
	END

	IF @PageDefinitionID=0
	BEGIN	
		INSERT INTO tblPageDefinition
		(
			fkPageTypeID,
			fkPageDefinitionTypeID,
			Name,
			Property,
			Required,
			Advanced,
			Searchable,
			DefaultValueType,
			EditCaption,
			HelpText,
			ObjectProgID,
			LongStringSettings,
			SettingsID,
			FieldOrder,
			LanguageSpecific,
			DisplayEditUI,
			ExistsOnModel
		)
		VALUES
		(
			@PageTypeID,
			@PageDefinitionTypeID,
			@Name,
			@Type,
			@Required,
			@Advanced,
			@Searchable,
			@DefaultValueType,
			@EditCaption,
			@HelpText,
			@ObjectProgID,
			@LongStringSettings,
			@SettingsID,
			@FieldOrder,
			@LanguageSpecific,
			@DisplayEditUI,
			@ExistsOnModel
		)
		SET @PageDefinitionID =  SCOPE_IDENTITY() 
	END
	ELSE
	BEGIN
		UPDATE tblPageDefinition SET
			Name 		= @Name,
			fkPageDefinitionTypeID	= @PageDefinitionTypeID,
			Property 	= @Type,
			Required 	= @Required,
			Advanced 	= @Advanced,
			Searchable 	= @Searchable,
			DefaultValueType = @DefaultValueType,
			EditCaption 	= @EditCaption,
			HelpText 	= @HelpText,
			ObjectProgID 	= @ObjectProgID,
			LongStringSettings = @LongStringSettings,
			SettingsID = @SettingsID,
			LanguageSpecific = @LanguageSpecific,
			FieldOrder = @FieldOrder,
			DisplayEditUI = @DisplayEditUI,
			ExistsOnModel = @ExistsOnModel
		WHERE pkID=@PageDefinitionID
	END
	DELETE FROM tblPropertyDefault WHERE fkPageDefinitionID=@PageDefinitionID
	IF @LanguageSpecific<3
	BEGIN
		/* NOTE: Here we take into consideration that language neutral dynamic properties are always stored on language 
			with id 1 (which perhaps should be changed and in that case the special handling here could be removed). */
		IF @PageTypeID IS NULL
		BEGIN
			DELETE tblProperty
			FROM tblProperty
			INNER JOIN tblPage ON tblPage.pkID=tblProperty.fkPageID
			WHERE fkPageDefinitionID=@PageDefinitionID AND tblProperty.fkLanguageBranchID<>1
		END
		ELSE
		BEGIN
			DELETE tblProperty
			FROM tblProperty
			INNER JOIN tblPage ON tblPage.pkID=tblProperty.fkPageID
			WHERE fkPageDefinitionID=@PageDefinitionID AND tblProperty.fkLanguageBranchID<>tblPage.fkMasterLanguageBranchID
		END
		DELETE tblWorkProperty
		FROM tblWorkProperty
		INNER JOIN tblWorkPage ON tblWorkProperty.fkWorkPageID=tblWorkPage.pkID
		INNER JOIN tblPage ON tblPage.pkID=tblWorkPage.fkPageID
		WHERE fkPageDefinitionID=@PageDefinitionID AND tblWorkPage.fkLanguageBranchID<>tblPage.fkMasterLanguageBranchID

		DELETE 
			tblCategoryPage
		FROM
			tblCategoryPage
		INNER JOIN
			tblPage
		ON
			tblPage.pkID = tblCategoryPage.fkPageID
		WHERE
			CategoryType = @PageDefinitionID
		AND
			tblCategoryPage.fkLanguageBranchID <> tblPage.fkMasterLanguageBranchID

		DELETE 
			tblWorkCategory
		FROM
			tblWorkCategory
		INNER JOIN 
			tblWorkPage
		ON
			tblWorkCategory.fkWorkPageID = tblWorkPage.pkID
		INNER JOIN
			tblPage
		ON
			tblPage.pkID = tblWorkPage.fkPageID
		WHERE
			CategoryType = @PageDefinitionID
		AND
			tblWorkPage.fkLanguageBranchID <> tblPage.fkMasterLanguageBranchID
	END
END
GO

PRINT N'Update complete.';

GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7028

GO
PRINT N'Update complete.';
GO

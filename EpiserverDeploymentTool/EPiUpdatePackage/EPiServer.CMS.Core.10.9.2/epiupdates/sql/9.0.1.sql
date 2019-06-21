--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7023)
				select 0, 'Already correct database version'
            else if (@ver = 7022)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery


GO
PRINT N'Dropping [dbo].[tblPropertyDefinition].[IDX_tblPropertyDefinition_Name]...';


GO
DROP INDEX [IDX_tblPropertyDefinition_Name]
    ON [dbo].[tblPropertyDefinition];


GO
PRINT N'Altering [dbo].[tblPropertyDefinition]...';


GO
ALTER TABLE [dbo].[tblPropertyDefinition] ALTER COLUMN [Name] NVARCHAR (100) NOT NULL;


GO
PRINT N'Creating [dbo].[tblPropertyDefinition].[IDX_tblPropertyDefinition_Name]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblPropertyDefinition_Name]
    ON [dbo].[tblPropertyDefinition]([Name] ASC);


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


GO
PRINT N'Dropping [dbo].[netActivityLogAssociatedAndRelatedList]...';


GO
DROP PROCEDURE [dbo].[netActivityLogAssociatedAndRelatedList];


GO
PRINT N'Dropping [dbo].[netActivityLogAssociatedOrRelatedList]...';


GO
DROP PROCEDURE [dbo].[netActivityLogAssociatedOrRelatedList];


GO
PRINT N'Creating [dbo].[tblActivityLogAssociation].[IDX_tblActivityLogAssociation_To]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblActivityLogAssociation_To]
    ON [dbo].[tblActivityLogAssociation]([To] ASC);


GO
PRINT N'Altering [dbo].[netActivityLogAssociationDeleteRelated]...';


GO
ALTER PROCEDURE [dbo].[netActivityLogAssociationDeleteRelated]
(
	@AssociatedItem	[nvarchar](255),
	@RelatedItem	[nvarchar](255)
)

AS            
BEGIN
	DECLARE @RelatedItemLike NVARCHAR(256)
	SET @RelatedItemLike = @RelatedItem + '%'
	DELETE FROM [tblActivityLogAssociation] 
	FROM [tblActivityLogAssociation] AS TCLA INNER JOIN [tblActivityLog] AS TCL ON TCLA.[To] = TCL.pkID
	WHERE (TCLA.[From] = @AssociatedItem AND TCL.[RelatedItem] LIKE @RelatedItemLike)
	OR (TCLA.[From] LIKE @RelatedItemLike AND TCL.[RelatedItem] LIKE @AssociatedItem)
END
GO
PRINT N'Altering [dbo].[netActivityLogEntrySave]...';


GO
ALTER PROCEDURE [dbo].[netActivityLogEntrySave]
  (@LogData          [nvarchar](max) = NULL,
   @Type			 [nvarchar](255),
   @Action			 INTEGER = 0,
   @ChangedBy        [nvarchar](255),
   @RelatedItem		 [nvarchar](255),
   @Deleted			 [BIT] =  0,	
   @Id				 BIGINT = 0 OUTPUT,
   @ChangeDate       DATETIME,
   @Associations	 dbo.StringParameterTable READONLY
)

AS            
BEGIN
	IF (@Id = 0)
	BEGIN
       INSERT INTO [tblActivityLog] VALUES(@LogData,
                                       @ChangeDate,
                                       @Type,
                                       @Action,
                                       @ChangedBy,
									   @RelatedItem, 
									   @Deleted)
		SET @Id = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE [tblActivityLog] SET
			[LogData] = @LogData,
			[ChangeDate] = @ChangeDate,
			[Type] = @Type,
			[Action] = @Action,
			[ChangedBy] = @ChangedBy,
			[RelatedItem] = @RelatedItem,
			[Deleted] = @Deleted
		WHERE pkID = @Id
	END

	BEGIN
		MERGE tblActivityLogAssociation AS TARGET
		USING @Associations AS Source
		ON (Target.[To] = @Id AND Target.[From] = Source.String)
		WHEN NOT MATCHED BY Target THEN
			INSERT ([To], [From])
			VALUES (@Id, Source.String);
	END
END
GO

PRINT N'Creating [dbo].[netActivityLogAssociatedAllList]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogAssociatedAllList]
(
	@Associations	dbo.StringParameterTable READONLY,
	@StartIndex			BIGINT = NULL,
	@MaxCount			INT = NULL
)

AS            
BEGIN
	
	DECLARE @MatchAllCount INT
	SET @MatchAllCount = (SELECT COUNT(*) FROM @Associations);

	--Get all entries that match any uri
	WITH MatchedUrisCTE
	AS
	(
		SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
				FROM [tblActivityLog]
				INNER JOIN tblActivityLogAssociation ON pkID = [To]
				WHERE (EXISTS(SELECT * FROM @Associations WHERE [From] LIKE String + '%'))
		UNION ALL 
		SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
				FROM [tblActivityLog]
				WHERE 
				(EXISTS(SELECT * FROM @Associations WHERE RelatedItem LIKE String + '%'))
	),
	--Filter out to get only entries that match all of the uris
	GroupedMatchedUrisCTE
	AS
	(
		SELECT DISTINCT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
				FROM MatchedUrisCTE
				GROUP BY pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
				HAVING COUNT(pkID) = @MatchAllCount
	),
	
	-- Paged result
	PagedResultCTE AS
	(
		SELECT TOP(@MaxCount) TCL.pkID, TCL.Action, TCL.Type, TCL.ChangeDate, TCL.ChangedBy, TCL.LogData,
			TCL.RelatedItem, TCL.Deleted, 
			(SELECT COUNT(*) FROM GroupedMatchedUrisCTE) AS 'TotalCount'
		FROM GroupedMatchedUrisCTE as TCL
		WHERE TCL.pkID <= @StartIndex
		ORDER BY TCL.pkID DESC
	)

	SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted, TotalCount FROM PagedResultCTE	
END
GO
PRINT N'Creating [dbo].[netActivityLogAssociatedAnyList]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogAssociatedAnyList]
(
	@Associations	 dbo.StringParameterTable READONLY,
	@StartIndex			BIGINT = NULL,
	@MaxCount			INT = NULL
)

AS            
BEGIN

	WITH MatchedAssociatedOrRelatedIdsCTE
	AS
	(
		SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted,
		ROW_NUMBER() OVER (ORDER BY pkID) AS TotalCount
		FROM
		(SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
			FROM [tblActivityLog] 
			LEFT OUTER JOIN [tblActivityLogAssociation] TAR ON pkID = TAR.[To]
			WHERE 
				(EXISTS(SELECT * FROM @Associations WHERE RelatedItem LIKE String + '%')
				AND
				Deleted = 0)
				OR
				(EXISTS(SELECT * FROM @Associations WHERE TAR.[From] LIKE String + '%')
				AND
				Deleted = 0))
		AS Result
	),
	PagedResultCTE AS
	(
		SELECT TOP(@MaxCount) TCL.pkID, TCL.Action, TCL.Type, TCL.ChangeDate, TCL.ChangedBy, TCL.LogData,
			TCL.RelatedItem, TCL.Deleted, 
			(SELECT COUNT(*) FROM MatchedAssociatedOrRelatedIdsCTE) AS 'TotalCount'
		FROM MatchedAssociatedOrRelatedIdsCTE  as TCL
		WHERE TCL.pkID <= @StartIndex
		ORDER BY TCL.pkID DESC
	)

	SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted, TotalCount FROM PagedResultCTE	

END
GO
PRINT N'Creating [dbo].[netActivityLogAssociatedList]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogAssociatedList]
(
	@MatchAll			dbo.StringParameterTable READONLY,
	@MatchAny			dbo.StringParameterTable READONLY,
	@StartIndex			BIGINT = NULL,
	@MaxCount			INT = NULL
)

AS            
BEGIN
	DECLARE @MatchAllCount INT
	SET @MatchAllCount = (SELECT COUNT(*) FROM @MatchAll);

	--Get all entries that match any uri
	WITH MatchedUrisCTE
	AS
	(
		SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
				FROM [tblActivityLog]
				INNER JOIN tblActivityLogAssociation ON pkID = [To]
				WHERE (EXISTS(SELECT * FROM @MatchAll WHERE [From] LIKE String + '%'))
		UNION ALL 
		SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
				FROM [tblActivityLog]
				WHERE 
				(EXISTS(SELECT * FROM @MatchAll WHERE RelatedItem LIKE String + '%'))
	),
	--Filter out to get only entries that match all of the uris
	GroupedMatchedUrisCTE
	AS
	(
		SELECT DISTINCT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
				FROM MatchedUrisCTE
				GROUP BY pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
				HAVING COUNT(pkID) = @MatchAllCount
	),
	
	-- Then Match Any
	MatchedAssociatedOrRelatedIdsCTE
	AS
	(
		SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted,
		ROW_NUMBER() OVER (ORDER BY pkID) AS TotalCount
		FROM
		(SELECT T.pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
			FROM GroupedMatchedUrisCTE as T
			LEFT OUTER JOIN [tblActivityLogAssociation] TAR ON pkID = TAR.[To]
			WHERE 
				(EXISTS(SELECT * FROM @MatchAny WHERE RelatedItem LIKE String + '%') AND Deleted = 0)
				OR
				(EXISTS(SELECT * FROM @MatchAny WHERE TAR.[From] LIKE String + '%') AND Deleted = 0))
		AS Result
	),

	--get paged result
	PagedResultCTE AS
	(
		SELECT TOP(@MaxCount) TCL.pkID, TCL.Action, TCL.Type, TCL.ChangeDate, TCL.ChangedBy, TCL.LogData,
			TCL.RelatedItem, TCL.Deleted, 
			(SELECT COUNT(*) FROM MatchedAssociatedOrRelatedIdsCTE) AS 'TotalCount'
		FROM MatchedAssociatedOrRelatedIdsCTE  as TCL
		WHERE TCL.pkID <= @StartIndex
		ORDER BY TCL.pkID DESC
	)

	SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted, TotalCount FROM PagedResultCTE	
END
GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7023
GO

PRINT N'Update complete.';


GO

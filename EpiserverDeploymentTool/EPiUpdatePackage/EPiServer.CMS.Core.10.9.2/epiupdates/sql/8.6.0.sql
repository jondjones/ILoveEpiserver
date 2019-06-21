--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7018)
				select 0, 'Already correct database version'
            else if (@ver = 7017)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO

PRINT N'Rename [dbo].[tblChangeLog] to tblActivityLog';


GO
EXECUTE sp_rename @objname = N'[dbo].[tblChangeLog]', @newname = N'tblActivityLog', @objtype = N'OBJECT';


GO
PRINT N'Dropping [dbo].[tblActivityLog].[IDX_tblChangeLog_ChangeDate]...';


GO
DROP INDEX [IDX_tblChangeLog_ChangeDate]
    ON [dbo].[tblActivityLog];


GO
PRINT N'Dropping [dbo].[tblActivityLog].[IDX_tblChangeLog_Pkid_ChangeDate]...';


GO
DROP INDEX [IDX_tblChangeLog_Pkid_ChangeDate]
    ON [dbo].[tblActivityLog];


GO
PRINT N'Dropping [dbo].[DF_tblChangeLog_Action]...';


GO
ALTER TABLE [dbo].[tblActivityLog] DROP CONSTRAINT [DF_tblChangeLog_Action];


GO
PRINT N'Dropping [dbo].[DF_tblChangeLog_Category]...';


GO
ALTER TABLE [dbo].[tblActivityLog] DROP CONSTRAINT [DF_tblChangeLog_Category];


GO
PRINT N'Dropping [dbo].[DF_tblChangeLog_ChangeDate]...';


GO
ALTER TABLE [dbo].[tblActivityLog] DROP CONSTRAINT [DF_tblChangeLog_ChangeDate];


GO
PRINT N'Dropping [dbo].[netChangeLogSave]...';


GO
DROP PROCEDURE [dbo].[netChangeLogSave];


GO
PRINT N'Creating [dbo].[StringParameterTable]...';


GO
CREATE TYPE [dbo].[StringParameterTable] AS TABLE (
    [String] NVARCHAR (255) NULL);


GO
PRINT N'Starting rebuilding table [dbo].[tblActivityLog]...';


GO
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

CREATE TABLE [dbo].[tmp_ms_xx_tblActivityLog] (
    [pkID]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [LogData]     NVARCHAR (MAX) NULL,
    [ChangeDate]  DATETIME       NOT NULL,
    [Type]        NVARCHAR (50)  NOT NULL,
    [Action]      INT            CONSTRAINT [DF_tblActivityLog_Action] DEFAULT ((0)) NOT NULL,
    [ChangedBy]   NVARCHAR (255) NOT NULL,
    [RelatedItem] NVARCHAR (255) NULL,
    [Deleted]     BIT            DEFAULT (0) NOT NULL,
    CONSTRAINT [tmp_ms_xx_constraint_PK_tblActivityLog] PRIMARY KEY CLUSTERED ([pkID] ASC)
);

IF EXISTS (SELECT TOP 1 1 
           FROM   [dbo].[tblActivityLog])
    BEGIN
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_tblActivityLog] ON;
        INSERT INTO [dbo].[tmp_ms_xx_tblActivityLog] ([pkID], [LogData], [ChangeDate], [Type], [Action], [ChangedBy])
        SELECT   [pkID],
                 [LogData],
                 [ChangeDate],
				 CASE [Category] 
					WHEN 1 THEN 'Content'
					WHEN 2 THEN 'File'
					WHEN 3 THEN 'Directory'
					ELSE 'Unknown' 
					END,
                 [Action],
                 [ChangedBy]
        FROM     [dbo].[tblActivityLog]
        ORDER BY [pkID] ASC;
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_tblActivityLog] OFF;
    END

DROP TABLE [dbo].[tblActivityLog];

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_tblActivityLog]', N'tblActivityLog';

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_constraint_PK_tblActivityLog]', N'PK_tblActivityLog', N'OBJECT';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


GO
PRINT N'Creating [dbo].[tblActivityLog].[IDX_tblActivityLog_ChangeDate]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblActivityLog_ChangeDate]
    ON [dbo].[tblActivityLog]([ChangeDate] ASC);


GO
PRINT N'Creating [dbo].[tblActivityLog].[IDX_tblActivityLog_Pkid_ChangeDate]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblActivityLog_Pkid_ChangeDate]
    ON [dbo].[tblActivityLog]([pkID] ASC, [ChangeDate] ASC);


GO
PRINT N'Creating [dbo].[tblActivityLog].[IDX_tblActivityLog_RelatedItem]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblActivityLog_RelatedItem]
    ON [dbo].[tblActivityLog]([RelatedItem] ASC)
    INCLUDE([Deleted]);


GO
PRINT N'Creating [dbo].[tblActivityLogAssociation]...';


GO
CREATE TABLE [dbo].[tblActivityLogAssociation] (
    [From] NVARCHAR (255) NOT NULL,
    [To]   BIGINT         NOT NULL,
    CONSTRAINT [PK_tblActivityLogAssociation] PRIMARY KEY NONCLUSTERED ([From] ASC, [To] ASC)
);


GO
PRINT N'Creating [dbo].[tblActivityLogAssociation].[IDX_tblActivityLogAssociation_From]...';


GO
CREATE CLUSTERED INDEX [IDX_tblActivityLogAssociation_From]
    ON [dbo].[tblActivityLogAssociation]([From] ASC);


GO
PRINT N'Creating [dbo].[tblActivityLogComment]...';


GO
CREATE TABLE [dbo].[tblActivityLogComment] (
    [pkID]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [EntryId]     BIGINT         NOT NULL,
    [Author]      NVARCHAR (255) NULL,
    [Created]     DATETIME       NOT NULL,
    [LastUpdated] DATETIME       NOT NULL,
    [Message]     NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_tblActivityLogComment] PRIMARY KEY CLUSTERED ([pkID] ASC)
);


GO
PRINT N'Creating [dbo].[tblActivityLogComment].[IDX_tblActivityLogComment_EntryId]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblActivityLogComment_EntryId]
    ON [dbo].[tblActivityLogComment]([EntryId] ASC);


GO
PRINT N'Creating [dbo].[FK_tblActivityLogAssociation_tblActivityLog]...';


GO
ALTER TABLE [dbo].[tblActivityLogAssociation] WITH NOCHECK
    ADD CONSTRAINT [FK_tblActivityLogAssociation_tblActivityLog] FOREIGN KEY ([To]) REFERENCES [dbo].[tblActivityLog] ([pkID]) ON DELETE CASCADE;


GO
PRINT N'Creating [dbo].[FK_tblActivityLogComment_tblActivityLog]...';


GO
ALTER TABLE [dbo].[tblActivityLogComment] WITH NOCHECK
    ADD CONSTRAINT [FK_tblActivityLogComment_tblActivityLog] FOREIGN KEY ([EntryId]) REFERENCES [dbo].[tblActivityLog] ([pkID]) ON DELETE CASCADE;


GO
PRINT N'Altering [dbo].[netChangeLogGetCount]...';


GO
ALTER PROCEDURE [dbo].[netChangeLogGetCount]
(
	@from 	                DATETIME = NULL,
	@to	                    DATETIME = NULL,
	@type 					[nvarchar](255) = NULL,
	@action 				INT = 0,
	@changedBy				[nvarchar](255) = NULL,
	@startSequence			BIGINT = 0,
	@deleted				BIT = 0,
	@count                  BIGINT = 0 OUTPUT)
AS
BEGIN    
        SELECT @count = count(*)
        FROM [tblActivityLog] TCL
        WHERE 
        ((@startSequence = 0) OR (TCL.pkID >= @startSequence)) AND
		((@from IS NULL) OR (TCL.ChangeDate >= @from)) AND
		((@to IS NULL) OR (TCL.ChangeDate <= @to)) AND  
        ((@type IS NULL) OR (@type = TCL.Type)) AND
        ((@action = 0) OR (@action = TCL.Action)) AND
        ((@changedBy IS NULL) OR (@changedBy = TCL.ChangedBy)) AND
		((@deleted = 1) OR (TCL.Deleted = 0))

END
GO
PRINT N'Altering [dbo].[netChangeLogGetCountBackwards]...';


GO
ALTER PROCEDURE [dbo].[netChangeLogGetCountBackwards]
(
	@from 	                 DATETIME = NULL,
	@to	                     DATETIME = NULL,
	@type 					 [nvarchar](255) = NULL,
	@action 				 INT = 0,
	@changedBy				 [nvarchar](255) = NULL,
	@startSequence			 BIGINT = 0,
	@deleted				 BIT =  0,	
	@count                   BIGINT = 0 OUTPUT)
AS
BEGIN    
        SELECT @count = count(*)
        FROM [tblActivityLog] TCL
        WHERE 
        (TCL.pkID <= @startSequence) AND
		((@from IS NULL) OR (TCL.ChangeDate >= @from)) AND
		((@to IS NULL) OR (TCL.ChangeDate <= @to)) AND  
        ((@type IS NULL) OR (@type = TCL.Type)) AND
        ((@action = 0) OR (@action = TCL.Action)) AND
        ((@changedBy IS NULL) OR (@changedBy = TCL.ChangedBy)) AND
		((@deleted = 1) OR (TCL.Deleted = 0))

		
END
GO
PRINT N'Altering [dbo].[netChangeLogGetHighestSeqNum]...';


GO
ALTER PROCEDURE [dbo].[netChangeLogGetHighestSeqNum]
(
	@count BIGINT = 0 OUTPUT
)
AS
BEGIN
	select @count = MAX(pkID) from [tblActivityLog]
END
SET QUOTED_IDENTIFIER ON
GO
PRINT N'Altering [dbo].[netChangeLogGetRowsBackwards]...';


GO
ALTER PROCEDURE [dbo].[netChangeLogGetRowsBackwards]
(
	@from 	                 DATETIME = NULL,
	@to	                     DATETIME = NULL,
	@type 					 [nvarchar](255) = NULL,
	@action 				 INT = NULL,
	@changedBy				 [nvarchar](255) = NULL,
	@startSequence			 BIGINT = NULL,
	@maxRows				 BIGINT,
	@deleted				 BIT = 0   
)
AS
BEGIN    
        SELECT top(@maxRows) *
        FROM [tblActivityLog] TCL
        WHERE 
        ((@startSequence IS NULL) OR (TCL.pkID <= @startSequence)) AND
		((@from IS NULL) OR (TCL.ChangeDate >= @from)) AND
		((@to IS NULL) OR (TCL.ChangeDate <= @to)) AND  
        ((@type IS NULL) OR (@type = TCL.Type)) AND
        ((@action IS NULL) OR (@action = TCL.Action)) AND
        ((@changedBy IS NULL) OR (@changedBy = TCL.ChangedBy)) AND
		((@deleted = 1) OR (TCL.Deleted = 0))
        
		ORDER BY TCL.pkID DESC
END
GO
PRINT N'Altering [dbo].[netChangeLogGetRowsForwards]...';


GO
ALTER PROCEDURE [dbo].[netChangeLogGetRowsForwards]
(
	@from 	                 DATETIME = NULL,
	@to	                     DATETIME = NULL,
	@type 					 [nvarchar](255) = NULL,
	@action 				 INT = NULL,
	@changedBy				 [nvarchar](255) = NULL,
	@startSequence			 BIGINT = NULL,
	@maxRows				 BIGINT,
	@deleted				 BIT = 0
)
AS
BEGIN    
        SELECT top(@maxRows) *
        FROM [tblActivityLog] TCL
        WHERE 
        ((@startSequence IS NULL) OR (TCL.pkID >= @startSequence)) AND
		((@from IS NULL) OR (TCL.ChangeDate >= @from)) AND
		((@to IS NULL) OR (TCL.ChangeDate <= @to)) AND  
        ((@type IS NULL) OR (@type = TCL.Type)) AND
        ((@action IS NULL) OR (@action = TCL.Action)) AND
        ((@changedBy IS NULL) OR (@changedBy = TCL.ChangedBy)) AND
		((@deleted = 1) OR (TCL.Deleted = 0))
        
		ORDER BY TCL.pkID ASC
END
GO
PRINT N'Altering [dbo].[netChangeLogTruncByRowsNDate]...';


GO
ALTER PROCEDURE [dbo].[netChangeLogTruncByRowsNDate]
(
	@RowsToTruncate BIGINT = NULL,
	@OlderThan DATETIME = NULL
)
AS
BEGIN	

	IF (@RowsToTruncate IS NOT NULL)
	BEGIN
		DELETE TOP(@RowsToTruncate) FROM [tblActivityLog] WHERE
		((@OlderThan IS NULL) OR (ChangeDate < @OlderThan))
		RETURN		
	END
	
	DELETE FROM [tblActivityLog] WHERE
	((@OlderThan IS NULL) OR (ChangeDate < @OlderThan))
	
END
GO
PRINT N'Altering [dbo].[netChangeLogTruncBySeqNDate]...';


GO
ALTER PROCEDURE [dbo].[netChangeLogTruncBySeqNDate]
(
	@LowestSequenceNumber BIGINT = NULL,
	@OlderThan DATETIME = NULL
)
AS
BEGIN	
	DELETE FROM [tblActivityLog] WHERE
	((@LowestSequenceNumber IS NULL) OR (pkID < @LowestSequenceNumber)) AND
	((@OlderThan IS NULL) OR (ChangeDate < @OlderThan))
END
GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7018
GO
PRINT N'Creating [dbo].[netActivityLogAssociatedAndRelatedList]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogAssociatedAndRelatedList]
(
	@AssociatedItem		[nvarchar](255),
	@RelatedItem		[nvarchar](255)
)

AS            
BEGIN
	SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
	FROM [tblActivityLog] INNER JOIN [tblActivityLogAssociation]
			ON [tblActivityLog].pkID = [tblActivityLogAssociation].[To]
			WHERE 
				[tblActivityLogAssociation].[From] LIKE @AssociatedItem + '%'
				AND
				[tblActivityLog].RelatedItem LIKE @RelatedItem + '%'
	ORDER BY pkID DESC	
END
GO
PRINT N'Creating [dbo].[netActivityLogAssociatedGetLowest]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogAssociatedGetLowest]
(
	@AssociatedItem		[nvarchar](255)
)

AS            
BEGIN
	SELECT MIN(pkID)
		FROM
		(SELECT pkID
			FROM [tblActivityLog]
			WHERE 
				RelatedItem = @AssociatedItem
				AND
				Deleted = 0
		UNION
			SELECT pkID
			FROM [tblActivityLog] 
			INNER JOIN [tblActivityLogAssociation] TAR ON pkID = TAR.[To]
			WHERE 
				TAR.[From] = @AssociatedItem 
				AND
				Deleted = 0) AS RESULT
END
GO
PRINT N'Creating [dbo].[netActivityLogAssociatedOrRelatedList]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogAssociatedOrRelatedList]
(
	@AssociatedItem		[nvarchar](255),
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
		(
		(SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
			FROM [tblActivityLog]
			WHERE 
				RelatedItem LIKE @AssociatedItem + '%'
				AND
				Deleted = 0
		UNION
			SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, RelatedItem, Deleted
			FROM [tblActivityLog] 
			INNER JOIN [tblActivityLogAssociation] TAR ON pkID = TAR.[To]
			WHERE 
				TAR.[From] LIKE @AssociatedItem + '%'
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

		
	SELECT pkID, Action, Type, ChangeDate, ChangedBy, LogData, 
		RelatedItem, Deleted, TotalCount FROM PagedResultCTE	
		ORDER BY pkID DESC	

END
GO
PRINT N'Creating [dbo].[netActivityLogAssociationDelete]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogAssociationDelete]
(
	@AssociatedItem	[nvarchar](255),
	@ChangeLogID  BIGINT = 0
)


AS            
BEGIN
	IF (@ChangeLogID = 0)
	BEGIN
		DELETE FROM [tblActivityLogAssociation] WHERE [From] = @AssociatedItem
	END
	ELSE 
	BEGIN
		DELETE FROM [tblActivityLogAssociation] WHERE [From] = @AssociatedItem
		AND [To] = @ChangeLogID
	END
	SELECT @@ROWCOUNT
END
GO
PRINT N'Creating [dbo].[netActivityLogAssociationDeleteRelated]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogAssociationDeleteRelated]
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
	WHERE TCLA.[From] = @AssociatedItem AND TCL.[RelatedItem] LIKE @RelatedItemLike
END
GO
PRINT N'Creating [dbo].[netActivityLogAssociationSave]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogAssociationSave]
(
	@AssociatedItem	[nvarchar](255),
	@ChangeLogID  BIGINT
)


AS            
BEGIN
	INSERT INTO [tblActivityLogAssociation] VALUES(@AssociatedItem, @ChangeLogID)
END
GO
PRINT N'Creating [dbo].[netActivityLogCommentDelete]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogCommentDelete]
(
	@Id  BIGINT
)
AS            
BEGIN
	DELETE FROM [tblActivityLogComment] WHERE [pkID] = @Id
END
GO
PRINT N'Creating [dbo].[netActivityLogCommentList]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogCommentList]
(
	@EntryId	[bigint]
)

AS            
BEGIN
	SELECT * FROM [tblActivityLogComment]
		WHERE [EntryId] = @EntryId
	ORDER BY pkID DESC
END
GO
PRINT N'Creating [dbo].[netActivityLogCommentLoad]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogCommentLoad]
(
	@Id	[bigint]
)

AS            
BEGIN
	SELECT * FROM [tblActivityLogComment]
		WHERE pkID = @Id
END
GO
PRINT N'Creating [dbo].[netActivityLogCommentSave]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogCommentSave]
(
	@Id			BIGINT = 0 OUTPUT,
	@EntryId	BIGINT, 
    @Author		NVARCHAR(255) = NULL, 
    @Created	DATETIME, 
    @LastUpdated DATETIME, 
    @Message	NVARCHAR(max)
)
AS            
BEGIN
	IF (@Id = 0)
	BEGIN
		INSERT INTO [tblActivityLogComment] VALUES(@EntryId, @Author, @Created, @Created, @Message)
		SET @Id = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE [tblActivityLogComment] SET
			[EntryId] = @EntryId,
			[Author] = @Author,
			[LastUpdated] = @LastUpdated,
			[Message] = @Message
	END
END
GO
PRINT N'Creating [dbo].[netActivityLogEntryLoad]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogEntryLoad]
(
   @Id				BIGINT
)

AS            
BEGIN
	SELECT * FROM [tblActivityLog]
	WHERE pkID = @Id
END
GO
PRINT N'Creating [dbo].[netActivityLogGetAssociations]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogGetAssociations]
(
	@Id		BIGINT
)

AS            
BEGIN

	SELECT RelatedItem AS Uri
		FROM [tblActivityLog] 
		WHERE 
			@Id = pkID AND
			RelatedItem IS NOT NULL 
	UNION
		(SELECT [From] AS Uri
		FROM [tblActivityLogAssociation] 
		WHERE 
			[To] = @Id )
END
GO
PRINT N'Creating [dbo].[netActivityLogTruncate]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogTruncate]
(
	@MaxRows BIGINT = NULL,
	@BeforeEntry BIGINT = NULL,
	@CreatedBefore DATETIME = NULL
)
AS
BEGIN	
	IF (@MaxRows IS NOT NULL)
	BEGIN
		DELETE TOP(@MaxRows) FROM [tblActivityLog] 
		WHERE ((@BeforeEntry IS NULL) OR (pkID < @BeforeEntry)) AND ((@CreatedBefore IS NULL) OR (ChangeDate < @CreatedBefore))
	END
	ELSE
	BEGIN
		DELETE FROM [tblActivityLog] 
		WHERE ((@BeforeEntry IS NULL) OR (pkID < @BeforeEntry)) AND ((@CreatedBefore IS NULL) OR (ChangeDate < @CreatedBefore))
	END
	RETURN @@ROWCOUNT
END
GO
PRINT N'Creating [dbo].[netActivityLogEntryDelete]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogEntryDelete]
(
   @Id	BIGINT
)

AS            
BEGIN
		UPDATE 
			[tblActivityLog]
		SET 
			[Deleted] = 1 
		WHERE 
			[pkID] = @Id  AND [Deleted] = 0

		EXEC netActivityLogGetAssociations @Id
END
GO
PRINT N'Creating [dbo].[netActivityLogEntrySave]...';


GO
CREATE PROCEDURE [dbo].[netActivityLogEntrySave]
  (@LogData          [nvarchar](max),
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

	EXEC netActivityLogGetAssociations @Id
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
	DELETE FROM tblContentSoftlink WHERE fkOwnerContentID =  @PageID AND OwnerLanguageID = @LangBranchID

	DELETE FROM tblProperty FROM tblProperty
	INNER JOIN tblPageDefinition ON tblPageDefinition.pkID=tblProperty.fkPageDefinitionID
	WHERE fkPageID=@PageID 
	AND fkLanguageBranchID=@LangBranchID
	AND fkPageTypeID IS NOT NULL
	
	DELETE FROM tblCategoryPage WHERE fkPageID=@PageID AND fkLanguageBranchID=@LangBranchID
		
	RETURN 1

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
PRINT N'Altering [dbo].[netCategoryDelete]...';

GO
ALTER PROCEDURE dbo.netCategoryDelete
(
    @CategoryID            INT
)
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

        CREATE TABLE #Reversed (pkID INT PRIMARY KEY)

        /* Find category and descendants */
        ;WITH Categories AS (
          SELECT pkID, 0 as [Level]
          FROM tblCategory
          WHERE pkID = @CategoryID
          UNION ALL
          SELECT c1.pkID, [Level] + 1
          FROM tblCategory c1 
            INNER JOIN Categories c2 ON c1.fkParentID = c2.pkID
         ) 

        /* Reverse order to avoid reference constraint errors */
        INSERT INTO #Reversed (pkID) 
        SELECT pkID FROM Categories ORDER BY [Level] DESC

        /* Delete any references from content tables */
        DELETE FROM tblCategoryPage WHERE fkCategoryID IN (SELECT pkID FROM #Reversed)
        DELETE FROM tblWorkCategory WHERE fkCategoryID IN (SELECT pkID FROM #Reversed)
        
        /* Delete the categories */
        DELETE FROM tblCategory WHERE pkID IN (SELECT pkID FROM #Reversed)

        DROP TABLE #Reversed

    RETURN 0
END

GO

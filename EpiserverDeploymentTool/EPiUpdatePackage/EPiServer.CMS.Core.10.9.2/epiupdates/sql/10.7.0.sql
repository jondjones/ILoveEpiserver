--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7045)
				select 0, 'Already correct database version'
            else if (@ver = 7044)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
GO

PRINT N'Altering [dbo].[tblApprovalDefinitionVersion]...';
GO

ALTER TABLE [dbo].[tblApprovalDefinitionVersion] ADD [RequireCommentOnApprove] [BIT] NOT NULL DEFAULT (0) 
GO

EXECUTE sp_rename @objname = N'[dbo].[tblApprovalDefinitionVersion].[DemandCommentOnReject]', @newname = N'RequireCommentOnReject', @objtype = N'COLUMN';
GO

PRINT N'Altering [dbo].[netApprovalDefinitionAddVersion]...';
GO

ALTER PROCEDURE [dbo].[netApprovalDefinitionAddVersion](
	@ApprovalDefinitionKey NVARCHAR (255),
	@SavedBy NVARCHAR (255),
	@Saved DATETIME2,
	@RequireCommentOnApprove BIT,
	@RequireCommentOnReject BIT,
	@IsEnabled BIT,
	@Steps [dbo].[AddApprovalDefinitionStepTable] READONLY,
	@Approvers [dbo].[AddApprovalDefinitionApproverTable] READONLY,
	@ApprovalDefinitionID INT OUT,
	@ApprovalDefinitionVersionID INT OUT)
AS
BEGIN
	SELECT @ApprovalDefinitionID = NULL, @ApprovalDefinitionVersionID = NULL

	-- Get or create an ApprovalDefinition for the ApprovalDefinitionKey
	SELECT @ApprovalDefinitionID = pkID FROM [dbo].[tblApprovalDefinition] WHERE ApprovalDefinitionKey = @ApprovalDefinitionKey
	IF (@ApprovalDefinitionID IS NULL)
	BEGIN
		DECLARE @DefinitionIDTable [dbo].[IDTable]
		INSERT INTO [dbo].[tblApprovalDefinition]([ApprovalDefinitionKey]) OUTPUT inserted.pkID INTO @DefinitionIDTable VALUES (@ApprovalDefinitionKey)
		SELECT @ApprovalDefinitionID = ID FROM @DefinitionIDTable
	END

	-- Add a new ApprovalDefinitionVersion to the definition
	DECLARE @VersionIDTable [dbo].[IDTable]
	INSERT INTO [dbo].[tblApprovalDefinitionVersion]([fkApprovalDefinitionID], [SavedBy], [Saved], [RequireCommentOnApprove], [RequireCommentOnReject], [IsEnabled]) OUTPUT inserted.pkID INTO @VersionIDTable VALUES (@ApprovalDefinitionID, @SavedBy, @Saved, @RequireCommentOnApprove, @RequireCommentOnReject, @IsEnabled)
	SELECT @ApprovalDefinitionVersionID = ID FROM @VersionIDTable

	-- Update the current version in the definition
	UPDATE [dbo].[tblApprovalDefinition]
	SET [fkCurrentApprovalDefinitionVersionID] = @ApprovalDefinitionVersionID
	WHERE pkID = @ApprovalDefinitionID

	-- Add steps
	DECLARE @StepTable TABLE (ID INT, StepIndex INT)
	INSERT INTO [dbo].[tblApprovalDefinitionStep]([fkApprovalDefinitionVersionID], [StepIndex], [StepName], [ApproversNeeded])
	OUTPUT inserted.pkID, inserted.StepIndex INTO @StepTable
	SELECT @ApprovalDefinitionVersionID, StepIndex, StepName, ApproversNeeded FROM @Steps
	
	-- Add approvers
	INSERT INTO [dbo].[tblApprovalDefinitionApprover]([fkApprovalDefinitionStepID], [fkApprovalDefinitionVersionID], [Username], [fkLanguageBranchID])
	SELECT step.ID, @ApprovalDefinitionVersionID, approver.Username, approver.fkLanguageBranchID FROM @Approvers approver
	JOIN @StepTable step ON approver.StepIndex = step.StepIndex

	-- Cleanup unused versions
	DELETE adv FROM [dbo].[tblApprovalDefinition] ad
	JOIN [dbo].[tblApprovalDefinitionVersion] adv ON ad.pkID = adv.fkApprovalDefinitionID
	LEFT JOIN [dbo].[tblApproval] a ON a.fkApprovalDefinitionVersionID = adv.pkID
	WHERE ad.pkID = @ApprovalDefinitionID AND ad.fkCurrentApprovalDefinitionVersionID != adv.pkID AND a.pkID IS NULL
END

GO

PRINT N'Altering [dbo].[netApprovalListByQuery]...';

GO
ALTER PROCEDURE [dbo].[netApprovalListByQuery](
	@StartIndex INT,
	@MaxCount INT,
	@Username NVARCHAR(255) = NULL,
	@StartedBy NVARCHAR(255) = NULL,
	@LanguageBranchID INT = NULL,
	@ApprovalKey NVARCHAR(255) = NULL,
	@DefinitionID INT = NULL,
	@DefinitionVersionID INT = NULL,
	@Status INT = NULL,
	@OnlyActiveSteps BIT = 0,
	@UserDecision BIT = NULL,
	@UserDecisionApproved BIT = NULL,
	@PrintQuery BIT = 0)
AS
BEGIN
	DECLARE @JoinApprovalDefinitionVersion BIT = 0
	DECLARE @JoinApprovalDefinitionApprover BIT = 0
	DECLARE @JoinApprovalStepDecision BIT = 0

	DECLARE @InvariantLanguageBranchID INT = NULL

	DECLARE @Wheres AS TABLE([String] NVARCHAR(MAX))

	IF @LanguageBranchID IS NOT NULL 
	BEGIN
		SELECT @InvariantLanguageBranchID = [pkID] FROM [dbo].[tblLanguageBranch] WHERE LanguageID = ''
		IF @LanguageBranchID = @InvariantLanguageBranchID
			SET @LanguageBranchID = NULL
		ELSE 
			INSERT INTO @Wheres SELECT '[approval].fkLanguageBranchID IN (@LanguageBranchID, @InvariantLanguageBranchID)'	
	END

	IF @Status IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].ApprovalStatus = @Status'

	IF @StartedBy IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].StartedBy = @StartedBy'

	IF @DefinitionVersionID IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].fkApprovalDefinitionVersionID = @DefinitionVersionID'

	IF @ApprovalKey IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].ApprovalKey LIKE @ApprovalKey + ''%''' 

	IF @DefinitionID IS NOT NULL 
	BEGIN
		SET @JoinApprovalDefinitionVersion = 1
		INSERT INTO @Wheres SELECT '[version].fkApprovalDefinitionID = @DefinitionID'
	END

	DECLARE @DecisionComparison NVARCHAR(MAX) = ''
	IF @UserDecision IS NULL OR @UserDecision = 1 
	BEGIN
		SET @DecisionComparison
			= CASE WHEN @Username IS NOT NULL THEN 'AND [decision].Username = @Username ' ELSE '' END   
			+ CASE WHEN @OnlyActiveSteps = 1 THEN 'AND [approval].ActiveStepIndex = [decision].StepIndex ' ELSE '' END   
			+ CASE WHEN @UserDecisionApproved IS NOT NULL THEN 'AND [decision].Approve = @UserDecisionApproved ' ELSE '' END   
		IF @DecisionComparison != '' OR @UserDecision = 1 
		BEGIN
			SET @JoinApprovalStepDecision = 1
			SET @DecisionComparison = '[decision].pkID IS NOT NULL ' + @DecisionComparison 
		END
	END

	DECLARE @DeclarationComparison NVARCHAR(MAX) = ''
	IF @Username IS NOT NULL AND (@UserDecision IS NULL OR @UserDecision = 0) 
	BEGIN
		SET @JoinApprovalDefinitionVersion = 1
		SET @JoinApprovalDefinitionApprover = 1
		SET @DeclarationComparison = '[approver].Username = @Username ' 
			+ CASE WHEN @OnlyActiveSteps = 1 THEN 'AND [approval].ActiveStepIndex = [step].StepIndex ' ELSE '' END   
			+ CASE WHEN @LanguageBranchID IS NOT NULL THEN 'AND (([approval].fkLanguageBranchID = @InvariantLanguageBranchID) OR ([approver].fkLanguageBranchID IN (@LanguageBranchID, @InvariantLanguageBranchID ))) ' ELSE '' END   
	END

	IF @DecisionComparison != '' AND @DeclarationComparison != ''
		INSERT INTO @Wheres SELECT '((' + @DecisionComparison + ') OR (' + @DeclarationComparison + '))'
	ELSE IF @DecisionComparison != ''
		INSERT INTO @Wheres SELECT @DecisionComparison
	ELSE IF @DeclarationComparison != ''
		INSERT INTO @Wheres SELECT @DeclarationComparison
	
	DECLARE @WhereSql NVARCHAR(MAX) 
	SELECT @WhereSql = COALESCE(@WhereSql + CHAR(13) + 'AND ', '') + [String] FROM @Wheres

	DECLARE @SelectSql NVARCHAR(MAX) = 'SELECT DISTINCT [approval].pkID, [approval].[Started] FROM [dbo].[tblApproval] [approval]' + CHAR(13)
		+ CASE WHEN @JoinApprovalDefinitionVersion = 1 THEN 'JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON [approval].fkApprovalDefinitionVersionID = [version].pkID' + CHAR(13) ELSE '' END   
		+ CASE WHEN @JoinApprovalDefinitionApprover = 1 THEN 'JOIN [dbo].[tblApprovalDefinitionStep] [step] ON [step].fkApprovalDefinitionVersionID = [version].pkID' + CHAR(13) ELSE '' END   
		+ CASE WHEN @JoinApprovalDefinitionApprover = 1 THEN 'JOIN [dbo].[tblApprovalDefinitionApprover] [approver] ON [approver].fkApprovalDefinitionStepID = [step].pkID' + CHAR(13) ELSE '' END   
		+ CASE WHEN @JoinApprovalStepDecision = 1 THEN 'LEFT JOIN [dbo].[tblApprovalStepDecision] [decision] ON [approval].pkID = [decision].fkApprovalID' + CHAR(13) ELSE '' END   

	DECLARE @Sql NVARCHAR(MAX) = @SelectSql 
	IF @WhereSql IS NOT NULL
		SET @Sql += 'WHERE ' + @WhereSql + CHAR(13)

	SET @Sql += 'ORDER BY [Started] DESC'

	SET @Sql = '
DECLARE @Ids AS TABLE([RowNr] [INT] IDENTITY(0,1), [ID] [INT] NOT NULL, [Started] DATETIME)

INSERT INTO @Ids
' + @Sql + '

DECLARE @TotalCount INT = (SELECT COUNT(*) FROM @Ids)

SELECT TOP(@MaxCount) [approval].*, @TotalCount AS ''TotalCount''
FROM [dbo].[tblApproval] [approval]
JOIN @Ids ids ON [approval].[pkID] = ids.[ID]
WHERE ids.RowNr >= @StartIndex
ORDER BY [approval].[Started] DESC'

	IF @PrintQuery = 1 
	BEGIN
		PRINT @SQL
	END ELSE BEGIN
		EXEC sp_executesql @Sql, 
			N'@Username NVARCHAR(255), @StartIndex INT, @MaxCount INT, @StartedBy NVARCHAR(255), @ApprovalKey NVARCHAR(255), @LanguageBranchID INT, @InvariantLanguageBranchID INT, @Status INT, @DefinitionVersionID INT, @DefinitionID INT, @UserDecisionApproved INT', 
			@Username = @Username, @StartIndex = @StartIndex, @MaxCount = @MaxCount, @StartedBy = @StartedBy, @ApprovalKey = @ApprovalKey, @LanguageBranchID = @LanguageBranchID, @InvariantLanguageBranchID = @InvariantLanguageBranchID, @Status = @Status, @DefinitionVersionID = @DefinitionVersionID, @DefinitionID = @DefinitionID, @UserDecisionApproved = @UserDecisionApproved
	END
END
GO

PRINT N'Dropping [dbo].[netApprovalDefinitionAddVersion]...';
GO

DROP PROCEDURE [dbo].[netApprovalDefinitionAddVersion]
GO

PRINT N'Dropping [dbo].[AddApprovalDefinitionStepTable]...';

DROP TYPE [dbo].[AddApprovalDefinitionStepTable]
GO

PRINT N'Creating [dbo].[AddApprovalDefinitionStepTable]...';

CREATE TYPE [dbo].[AddApprovalDefinitionStepTable] AS TABLE(
	[StepIndex] [int] NOT NULL,
	[StepName] [nvarchar](255) NULL,
	[ReviewersNeeded] [int] NOT NULL
)
GO

PRINT N'Renaming [dbo].[AddApprovalDefinitionApproverTable]...';
GO

EXEC sp_rename '[dbo].[AddApprovalDefinitionApproverTable]', 'AddApprovalDefinitionReviewerTable'
GO

PRINT N'Renaming [dbo].[tblApprovalDefinitionStep].[ApproversNeeded]...';
GO

EXEC sp_rename '[dbo].[tblApprovalDefinitionStep].[ApproversNeeded]', 'ReviewersNeeded', 'COLUMN'
GO

PRINT N'Renaming [dbo].[tblApprovalDefinitionApprover]...';
GO

EXEC sp_rename '[dbo].[tblApprovalDefinitionApprover]', 'tblApprovalDefinitionReviewer'
GO

PRINT N'Renaming [dbo].[tblApprovalDefinitionReviewer].[IDX_tblApprovalDefinitionApprover_fkApprovalDefinitionVersionID]...';
GO

EXEC sp_rename '[dbo].[tblApprovalDefinitionReviewer].[IDX_tblApprovalDefinitionApprover_fkApprovalDefinitionVersionID]','IDX_tblApprovalDefinitionReviewer_fkApprovalDefinitionVersionID','INDEX'
GO

PRINT N'Renaming [dbo].[tblApprovalDefinitionReviewer].[IDX_tblApprovalDefinitionApprover_Username]...';
GO

EXEC sp_rename '[dbo].[tblApprovalDefinitionReviewer].[IDX_tblApprovalDefinitionApprover_Username]','IDX_tblApprovalDefinitionReviewer_Username'
GO

PRINT N'Renaming [dbo].[FK_tblApprovalDefinitionApprover_tblApprovalDefinitionStep]...';
GO

EXEC sp_rename '[dbo].[FK_tblApprovalDefinitionApprover_tblApprovalDefinitionStep]', 'FK_tblApprovalDefinitionReviewer_tblApprovalDefinitionStep', 'OBJECT'
GO

PRINT N'Renaming [dbo].[FK_tblApprovalDefinitionApprover_tblApprovalDefinitionVersion]...';
GO

EXEC sp_rename '[dbo].[FK_tblApprovalDefinitionApprover_tblApprovalDefinitionVersion]' , 'FK_tblApprovalDefinitionReviewer_tblApprovalDefinitionVersion', 'OBJECT'
GO

PRINT N'Renaming [dbo].[FK_tblApprovalDefinitionApprover_tblLanguageBranch]...';
GO

EXEC sp_rename '[dbo].[FK_tblApprovalDefinitionApprover_tblLanguageBranch]', 'FK_tblApprovalDefinitionReviewer_tblLanguageBranch', 'OBJECT'
GO

PRINT N'Renaming [dbo].[PK_tblApprovalDefinitionApprover]...';
GO

EXEC sp_rename '[dbo].[PK_tblApprovalDefinitionApprover]', 'PK_tblApprovalDefinitionReviewer', 'OBJECT'
GO

PRINT N'Creating [dbo].[netApprovalDefinitionAddVersion]...';
GO

CREATE PROCEDURE [dbo].[netApprovalDefinitionAddVersion](
	@ApprovalDefinitionKey NVARCHAR (255),
	@SavedBy NVARCHAR (255),
	@Saved DATETIME2,
	@RequireCommentOnApprove BIT,
	@RequireCommentOnReject BIT,
	@IsEnabled BIT,
	@Steps [dbo].[AddApprovalDefinitionStepTable] READONLY,
	@Reviewers [dbo].[AddApprovalDefinitionReviewerTable] READONLY,
	@ApprovalDefinitionID INT OUT,
	@ApprovalDefinitionVersionID INT OUT)
AS
BEGIN
	SELECT @ApprovalDefinitionID = NULL, @ApprovalDefinitionVersionID = NULL

	-- Get or create an ApprovalDefinition for the ApprovalDefinitionKey
	SELECT @ApprovalDefinitionID = pkID FROM [dbo].[tblApprovalDefinition] WHERE ApprovalDefinitionKey = @ApprovalDefinitionKey
	IF (@ApprovalDefinitionID IS NULL)
	BEGIN
		DECLARE @DefinitionIDTable [dbo].[IDTable]
		INSERT INTO [dbo].[tblApprovalDefinition]([ApprovalDefinitionKey]) OUTPUT inserted.pkID INTO @DefinitionIDTable VALUES (@ApprovalDefinitionKey)
		SELECT @ApprovalDefinitionID = ID FROM @DefinitionIDTable
	END

	-- Add a new ApprovalDefinitionVersion to the definition
	DECLARE @VersionIDTable [dbo].[IDTable]
	INSERT INTO [dbo].[tblApprovalDefinitionVersion]([fkApprovalDefinitionID], [SavedBy], [Saved], [RequireCommentOnApprove], [RequireCommentOnReject], [IsEnabled]) OUTPUT inserted.pkID INTO @VersionIDTable VALUES (@ApprovalDefinitionID, @SavedBy, @Saved, @RequireCommentOnApprove, @RequireCommentOnReject, @IsEnabled)
	SELECT @ApprovalDefinitionVersionID = ID FROM @VersionIDTable

	-- Update the current version in the definition
	UPDATE [dbo].[tblApprovalDefinition]
	SET [fkCurrentApprovalDefinitionVersionID] = @ApprovalDefinitionVersionID
	WHERE pkID = @ApprovalDefinitionID

	-- Add steps
	DECLARE @StepTable TABLE (ID INT, StepIndex INT)
	INSERT INTO [dbo].[tblApprovalDefinitionStep]([fkApprovalDefinitionVersionID], [StepIndex], [StepName], [ReviewersNeeded])
	OUTPUT inserted.pkID, inserted.StepIndex INTO @StepTable
	SELECT @ApprovalDefinitionVersionID, StepIndex, StepName, ReviewersNeeded FROM @Steps
	
	-- Add reviewers
	INSERT INTO [dbo].[tblApprovalDefinitionReviewer]([fkApprovalDefinitionStepID], [fkApprovalDefinitionVersionID], [Username], [fkLanguageBranchID])
	SELECT step.ID, @ApprovalDefinitionVersionID, reviewer.Username, reviewer.fkLanguageBranchID FROM @Reviewers reviewer
	JOIN @StepTable step ON reviewer.StepIndex = step.StepIndex

	-- Cleanup unused versions
	DELETE adv FROM [dbo].[tblApprovalDefinition] ad
	JOIN [dbo].[tblApprovalDefinitionVersion] adv ON ad.pkID = adv.fkApprovalDefinitionID
	LEFT JOIN [dbo].[tblApproval] a ON a.fkApprovalDefinitionVersionID = adv.pkID
	WHERE ad.pkID = @ApprovalDefinitionID AND ad.fkCurrentApprovalDefinitionVersionID != adv.pkID AND a.pkID IS NULL
END
GO

PRINT N'Creating [dbo].[netApprovalDefinitionGetCurrentVersion]...';
GO

ALTER PROCEDURE [dbo].[netApprovalDefinitionGetCurrentVersion](
	@ApprovalDefinitionIDs [dbo].[IDTable] READONLY,
	@ApprovalDefinitionKeys [dbo].[StringParameterTable] READONLY)
AS
BEGIN
	DECLARE @ApprovalDefinitionVersionIDs [dbo].[IDTable]

	IF EXISTS(select 1 from @ApprovalDefinitionIDs)  
		INSERT INTO @ApprovalDefinitionVersionIDs
		SELECT fkCurrentApprovalDefinitionVersionID 
		FROM [dbo].[tblApprovalDefinition] 
		JOIN @ApprovalDefinitionIDs ids ON ids.ID = pkID
	ELSE
		INSERT INTO @ApprovalDefinitionVersionIDs
		SELECT fkCurrentApprovalDefinitionVersionID 
		FROM [dbo].[tblApprovalDefinition] 
		JOIN @ApprovalDefinitionKeys keys ON keys.String = ApprovalDefinitionKey
	
	SELECT DISTINCT [definition].* FROM [dbo].[tblApprovalDefinition] [definition] 
	JOIN @ApprovalDefinitionVersionIDs [versionid] ON [definition].fkCurrentApprovalDefinitionVersionID = versionid.ID 
	
	SELECT [version].* FROM [dbo].[tblApprovalDefinitionVersion] [version]
	JOIN @ApprovalDefinitionVersionIDs [versionid] ON [version].pkID = versionid.ID 

	SELECT step.* FROM [dbo].[tblApprovalDefinitionStep] step
	JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON step.fkApprovalDefinitionVersionID = [version].pkID
	JOIN @ApprovalDefinitionVersionIDs [versionid] ON [version].pkID = versionid.ID 
	
	SELECT reviewer.* FROM [dbo].[tblApprovalDefinitionReviewer] reviewer 
	JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON reviewer.fkApprovalDefinitionVersionID = [version].pkID
	JOIN @ApprovalDefinitionVersionIDs [versionid] ON [version].pkID = versionid.ID 
END
GO

PRINT N'Creating [dbo].[netApprovalDefinitionVersionGet]...';
GO

ALTER PROCEDURE [dbo].[netApprovalDefinitionVersionGet](
	@ApprovalDefinitionVersionID INT)
AS
BEGIN
	SELECT [definition].* FROM [dbo].[tblApprovalDefinition] [definition] 
	JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON [definition].pkID = [version].fkApprovalDefinitionID
	WHERE [version].pkID = @ApprovalDefinitionVersionID
	
	SELECT * FROM [dbo].[tblApprovalDefinitionVersion] WHERE pkID = @ApprovalDefinitionVersionID

	SELECT * FROM [dbo].[tblApprovalDefinitionStep] WHERE fkApprovalDefinitionVersionID = @ApprovalDefinitionVersionID ORDER BY StepIndex ASC

	SELECT * FROM [dbo].[tblApprovalDefinitionReviewer] WHERE fkApprovalDefinitionVersionID = @ApprovalDefinitionVersionID
END
GO

PRINT N'Creating [dbo].[netApprovalDefinitionVersionList]...';
GO

ALTER PROCEDURE [dbo].[netApprovalDefinitionVersionList](
	@ApprovalDefinitionID INT)
AS
BEGIN
	SELECT DISTINCT [definition].* FROM [dbo].[tblApprovalDefinition] [definition] 
	JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON [definition].pkID = [version].fkApprovalDefinitionID
	WHERE [definition].pkID = @ApprovalDefinitionID
	
	SELECT * FROM [dbo].[tblApprovalDefinitionVersion] WHERE fkApprovalDefinitionID = @ApprovalDefinitionID

	SELECT step.* FROM [dbo].[tblApprovalDefinitionStep] step
	JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON step.fkApprovalDefinitionVersionID = [version].pkID
	WHERE [version].fkApprovalDefinitionID = @ApprovalDefinitionID
	
	SELECT reviewer.* FROM [dbo].[tblApprovalDefinitionReviewer] reviewer
	JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON reviewer.fkApprovalDefinitionVersionID = [version].pkID
	WHERE [version].fkApprovalDefinitionID = @ApprovalDefinitionID
END
GO

PRINT N'Creating [dbo].[netApprovalListByQuery]...';
GO

ALTER PROCEDURE [dbo].[netApprovalListByQuery](
	@StartIndex INT,
	@MaxCount INT,
	@Username NVARCHAR(255) = NULL,
	@StartedBy NVARCHAR(255) = NULL,
	@LanguageBranchID INT = NULL,
	@ApprovalKey NVARCHAR(255) = NULL,
	@DefinitionID INT = NULL,
	@DefinitionVersionID INT = NULL,
	@Status INT = NULL,
	@OnlyActiveSteps BIT = 0,
	@UserDecision BIT = NULL,
	@UserDecisionApproved BIT = NULL,
	@PrintQuery BIT = 0)
AS
BEGIN
	DECLARE @JoinApprovalDefinitionVersion BIT = 0
	DECLARE @JoinApprovalDefinitionReviewer BIT = 0
	DECLARE @JoinApprovalStepDecision BIT = 0

	DECLARE @InvariantLanguageBranchID INT = NULL

	DECLARE @Wheres AS TABLE([String] NVARCHAR(MAX))

	IF @LanguageBranchID IS NOT NULL 
	BEGIN
		SELECT @InvariantLanguageBranchID = [pkID] FROM [dbo].[tblLanguageBranch] WHERE LanguageID = ''
		IF @LanguageBranchID = @InvariantLanguageBranchID
			SET @LanguageBranchID = NULL
		ELSE 
			INSERT INTO @Wheres SELECT '[approval].fkLanguageBranchID IN (@LanguageBranchID, @InvariantLanguageBranchID)'	
	END

	IF @Status IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].ApprovalStatus = @Status'

	IF @StartedBy IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].StartedBy = @StartedBy'

	IF @DefinitionVersionID IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].fkApprovalDefinitionVersionID = @DefinitionVersionID'

	IF @ApprovalKey IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].ApprovalKey LIKE @ApprovalKey + ''%''' 

	IF @DefinitionID IS NOT NULL 
	BEGIN
		SET @JoinApprovalDefinitionVersion = 1
		INSERT INTO @Wheres SELECT '[version].fkApprovalDefinitionID = @DefinitionID'
	END

	DECLARE @DecisionComparison NVARCHAR(MAX) = ''
	IF @UserDecision IS NULL OR @UserDecision = 1 
	BEGIN
		SET @DecisionComparison
			= CASE WHEN @Username IS NOT NULL THEN 'AND [decision].Username = @Username ' ELSE '' END   
			+ CASE WHEN @OnlyActiveSteps = 1 THEN 'AND [approval].ActiveStepIndex = [decision].StepIndex ' ELSE '' END   
			+ CASE WHEN @UserDecisionApproved IS NOT NULL THEN 'AND [decision].Approve = @UserDecisionApproved ' ELSE '' END   
		IF @DecisionComparison != '' OR @UserDecision = 1 
		BEGIN
			SET @JoinApprovalStepDecision = 1
			SET @DecisionComparison = '[decision].pkID IS NOT NULL ' + @DecisionComparison 
		END
	END

	DECLARE @DeclarationComparison NVARCHAR(MAX) = ''
	IF @Username IS NOT NULL AND (@UserDecision IS NULL OR @UserDecision = 0) 
	BEGIN
		SET @JoinApprovalDefinitionVersion = 1
		SET @JoinApprovalDefinitionReviewer = 1
		SET @DeclarationComparison = '[reviewer].Username = @Username ' 
			+ CASE WHEN @OnlyActiveSteps = 1 THEN 'AND [approval].ActiveStepIndex = [step].StepIndex ' ELSE '' END   
			+ CASE WHEN @LanguageBranchID IS NOT NULL THEN 'AND (([approval].fkLanguageBranchID = @InvariantLanguageBranchID) OR ([reviewer].fkLanguageBranchID IN (@LanguageBranchID, @InvariantLanguageBranchID ))) ' ELSE '' END   
	END

	IF @DecisionComparison != '' AND @DeclarationComparison != ''
		INSERT INTO @Wheres SELECT '((' + @DecisionComparison + ') OR (' + @DeclarationComparison + '))'
	ELSE IF @DecisionComparison != ''
		INSERT INTO @Wheres SELECT @DecisionComparison
	ELSE IF @DeclarationComparison != ''
		INSERT INTO @Wheres SELECT @DeclarationComparison
	
	DECLARE @WhereSql NVARCHAR(MAX) 
	SELECT @WhereSql = COALESCE(@WhereSql + CHAR(13) + 'AND ', '') + [String] FROM @Wheres

	DECLARE @SelectSql NVARCHAR(MAX) = 'SELECT DISTINCT [approval].pkID, [approval].[Started] FROM [dbo].[tblApproval] [approval]' + CHAR(13)
		+ CASE WHEN @JoinApprovalDefinitionVersion = 1 THEN 'JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON [approval].fkApprovalDefinitionVersionID = [version].pkID' + CHAR(13) ELSE '' END   
		+ CASE WHEN @JoinApprovalDefinitionReviewer = 1 THEN 'JOIN [dbo].[tblApprovalDefinitionStep] [step] ON [step].fkApprovalDefinitionVersionID = [version].pkID' + CHAR(13) ELSE '' END   
		+ CASE WHEN @JoinApprovalDefinitionReviewer = 1 THEN 'JOIN [dbo].[tblApprovalDefinitionReviewer] [reviewer] ON [reviewer].fkApprovalDefinitionStepID = [step].pkID' + CHAR(13) ELSE '' END   
		+ CASE WHEN @JoinApprovalStepDecision = 1 THEN 'LEFT JOIN [dbo].[tblApprovalStepDecision] [decision] ON [approval].pkID = [decision].fkApprovalID' + CHAR(13) ELSE '' END   

	DECLARE @Sql NVARCHAR(MAX) = @SelectSql 
	IF @WhereSql IS NOT NULL
		SET @Sql += 'WHERE ' + @WhereSql + CHAR(13)

	SET @Sql += 'ORDER BY [Started] DESC'

	SET @Sql = '
DECLARE @Ids AS TABLE([RowNr] [INT] IDENTITY(0,1), [ID] [INT] NOT NULL, [Started] DATETIME)

INSERT INTO @Ids
' + @Sql + '

DECLARE @TotalCount INT = (SELECT COUNT(*) FROM @Ids)

SELECT TOP(@MaxCount) [approval].*, @TotalCount AS ''TotalCount''
FROM [dbo].[tblApproval] [approval]
JOIN @Ids ids ON [approval].[pkID] = ids.[ID]
WHERE ids.RowNr >= @StartIndex
ORDER BY [approval].[Started] DESC'

	IF @PrintQuery = 1 
	BEGIN
		PRINT @SQL
	END ELSE BEGIN
		EXEC sp_executesql @Sql, 
			N'@Username NVARCHAR(255), @StartIndex INT, @MaxCount INT, @StartedBy NVARCHAR(255), @ApprovalKey NVARCHAR(255), @LanguageBranchID INT, @InvariantLanguageBranchID INT, @Status INT, @DefinitionVersionID INT, @DefinitionID INT, @UserDecisionApproved INT', 
			@Username = @Username, @StartIndex = @StartIndex, @MaxCount = @MaxCount, @StartedBy = @StartedBy, @ApprovalKey = @ApprovalKey, @LanguageBranchID = @LanguageBranchID, @InvariantLanguageBranchID = @InvariantLanguageBranchID, @Status = @Status, @DefinitionVersionID = @DefinitionVersionID, @DefinitionID = @DefinitionID, @UserDecisionApproved = @UserDecisionApproved
	END
END
GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7045
GO

PRINT N'Update complete.';
GO

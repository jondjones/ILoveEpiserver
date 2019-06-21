--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7043)
				select 0, 'Already correct database version'
            else if (@ver = 7042)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
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

	DECLARE @Wheres AS TABLE([String] NVARCHAR(MAX))

	IF @LanguageBranchID IS NOT NULL 
	BEGIN
		DECLARE @InvariantLanguageBranchID INT = (SELECT [pkID] FROM [dbo].[tblLanguageBranch] WHERE LanguageID = '')
		IF @LanguageBranchID = @InvariantLanguageBranchID
			SET @LanguageBranchID = NULL
		ELSE 
		BEGIN
			DECLARE @InvariantLanguageBranchIDString NVARCHAR(16) = CAST(@InvariantLanguageBranchID AS NVARCHAR(16))
			DECLARE @LanguageBranchIDString NVARCHAR(16) = CAST(@LanguageBranchID AS NVARCHAR(16))
			INSERT INTO @Wheres SELECT '[approval].fkLanguageBranchID IN (' + @LanguageBranchIDString + ', ' + @InvariantLanguageBranchIDString + ')'	
		END
	END

	IF @Status IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].ApprovalStatus = ' + CAST(@Status AS NVARCHAR(16))

	IF @StartedBy IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].StartedBy = @StartedBy'

	IF @DefinitionVersionID IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].fkApprovalDefinitionVersionID = ' + CAST(@DefinitionVersionID AS NVARCHAR(16))

	IF @ApprovalKey IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].ApprovalKey LIKE @ApprovalKey + ''%''' 

	IF @DefinitionID IS NOT NULL 
	BEGIN
		SET @JoinApprovalDefinitionVersion = 1
		INSERT INTO @Wheres SELECT '[version].fkApprovalDefinitionID = ' + CAST(@DefinitionID AS NVARCHAR(16)) 
	END

	DECLARE @DecisionComparison NVARCHAR(200) = ''
	IF @UserDecision IS NULL OR @UserDecision = 1 
	BEGIN
		SET @DecisionComparison
			= CASE WHEN @Username IS NOT NULL THEN 'AND [decision].Username = @Username ' ELSE '' END   
			+ CASE WHEN @OnlyActiveSteps = 1 THEN 'AND [approval].ActiveStepIndex = [decision].StepIndex ' ELSE '' END   
			+ CASE WHEN @UserDecisionApproved IS NOT NULL THEN 'AND [decision].Approve = ' + CAST(@UserDecisionApproved AS NVARCHAR(1)) + ' ' ELSE '' END   
		IF @DecisionComparison != '' OR @UserDecision = 1 
		BEGIN
			SET @JoinApprovalStepDecision = 1
			SET @DecisionComparison = '[decision].pkID IS NOT NULL ' + @DecisionComparison 
		END
	END

	DECLARE @DeclarationComparison NVARCHAR(200) = ''
	IF @Username IS NOT NULL AND (@UserDecision IS NULL OR @UserDecision = 0) 
	BEGIN
		SET @JoinApprovalDefinitionVersion = 1
		SET @JoinApprovalDefinitionApprover = 1
		SET @DeclarationComparison = '[approver].Username = @Username ' 
			+ CASE WHEN @OnlyActiveSteps = 1 THEN 'AND [approval].ActiveStepIndex = [step].StepIndex ' ELSE '' END   
			+ CASE WHEN @LanguageBranchID IS NOT NULL THEN 'AND (([approval].fkLanguageBranchID = ' + @InvariantLanguageBranchIDString + ') OR ([approver].fkLanguageBranchID IN (' + @LanguageBranchIDString + ', ' + @InvariantLanguageBranchIDString + '))) ' ELSE '' END   
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

	IF @PrintQuery = 1 
	BEGIN
		PRINT @SQL
	END ELSE BEGIN
		DECLARE @Ids AS TABLE([RowNr] [INT] IDENTITY(0,1), [ID] [INT] NOT NULL, [Started] DATETIME)

		INSERT INTO @Ids
		EXEC sp_executesql @Sql, N'@Username NVARCHAR(255), @StartedBy NVARCHAR(255), @ApprovalKey NVARCHAR(255)', @Username = @Username, @StartedBy = @StartedBy, @ApprovalKey = @ApprovalKey

		DECLARE @TotalCount INT = (SELECT COUNT(*) FROM @Ids)
 
		SELECT TOP(@MaxCount) [approval].*, @TotalCount AS 'TotalCount'
		FROM [dbo].[tblApproval] [approval]
		JOIN @Ids ids ON [approval].[pkID] = ids.[ID]
		WHERE ids.RowNr >= @StartIndex
		ORDER BY [approval].[Started] DESC
	END
END

GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7043
GO

PRINT N'Update complete.';
GO

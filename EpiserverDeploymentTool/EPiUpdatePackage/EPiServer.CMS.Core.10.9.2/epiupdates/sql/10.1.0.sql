--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7038)
				select 0, 'Already correct database version'
            else if (@ver = 7037)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery


GO
PRINT N'Creating [dbo].[tblApprovalDefinition]...';


GO
CREATE TABLE [dbo].[tblApprovalDefinition] (
	[pkID] INT IDENTITY (1,1) NOT NULL,
	[ApprovalDefinitionKey] NVARCHAR (255) NOT NULL,
	[fkCurrentApprovalDefinitionVersionID] INT NULL, 
	CONSTRAINT [PK_tblApprovalDefinition] PRIMARY KEY CLUSTERED
	(
		[pkID] ASC
	)
)

GO
PRINT N'Creating [IDX_tblApprovalDefinition_ApprovalDefinitionKey]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblApprovalDefinition_ApprovalDefinitionKey] ON [dbo].[tblApprovalDefinition] 
(
	[ApprovalDefinitionKey] ASC
)

GO
PRINT N'Creating [dbo].[tblApprovalDefinitionVersion]...';


GO
CREATE TABLE [dbo].[tblApprovalDefinitionVersion] (
	[pkID] INT IDENTITY (1,1) NOT NULL,
	[fkApprovalDefinitionID] INT NOT NULL,
	[SavedBy] NVARCHAR (255) NOT NULL,
	[Saved] DATETIME2 NOT NULL,
	[DemandCommentOnReject] BIT NOT NULL DEFAULT (0),
	[IsEnabled] BIT NOT NULL DEFAULT (1),
	CONSTRAINT [PK_tblApprovalDefinitionVersion] PRIMARY KEY CLUSTERED 
	(
		[pkID] ASC
	),
	CONSTRAINT [FK_tblApprovalDefinitionVersion_tblApprovalDefinition] FOREIGN KEY 
	(
		[fkApprovalDefinitionID]
	) 
	REFERENCES [tblApprovalDefinition]
	(
		[pkID]
	) 
	ON DELETE CASCADE
)

GO
PRINT N'Altering [dbo].[tblApprovalDefinition]...';


GO
ALTER TABLE [dbo].[tblApprovalDefinition] 
ADD CONSTRAINT [FK_tblApprovalDefinition_tblApprovalDefinitionVersion] FOREIGN KEY 
(
	[fkCurrentApprovalDefinitionVersionID]
) 
REFERENCES [tblApprovalDefinitionVersion]
(
	[pkID]
)

GO
PRINT N'Creating [dbo].[tblApprovalDefinitionStep]...';


GO
CREATE TABLE [dbo].[tblApprovalDefinitionStep] (
	[pkID] INT IDENTITY (1,1) NOT NULL,
	[fkApprovalDefinitionVersionID] INT NOT NULL,
	[StepIndex] INT NOT NULL,
	[StepName] NVARCHAR (255) NULL,
	[ApproversNeeded] INT NOT NULL DEFAULT (1), 
	CONSTRAINT [PK_tblApprovalDefinitionStep] PRIMARY KEY CLUSTERED 
	(
		[pkID] ASC
	),
	CONSTRAINT [FK_tblApprovalDefinitionStep_tblApprovalDefinitionVersion] FOREIGN KEY 
	(
		[fkApprovalDefinitionVersionID]
	) 
	REFERENCES [tblApprovalDefinitionVersion]
	(
		[pkID]
	)
	ON DELETE CASCADE
)

GO
PRINT N'Creating [dbo].[tblApprovalDefinitionApprover]...';


GO
CREATE TABLE [dbo].[tblApprovalDefinitionApprover] (
	[pkID] INT IDENTITY (1,1) NOT NULL,
	[fkApprovalDefinitionStepID] INT NOT NULL, 
	[fkApprovalDefinitionVersionID] INT NOT NULL,
	[Username] NVARCHAR (255) NOT NULL,
	[fkLanguageBranchID] INT NOT NULL,
	CONSTRAINT [PK_tblApprovalDefinitionApprover] PRIMARY KEY CLUSTERED 
	(
		[pkID] ASC
	),
	CONSTRAINT [FK_tblApprovalDefinitionApprover_tblApprovalDefinitionStep] FOREIGN KEY 
	(
		[fkApprovalDefinitionStepID]
	) 
	REFERENCES [tblApprovalDefinitionStep]
	(
		[pkID]
	) 
	ON DELETE CASCADE, 
	CONSTRAINT [FK_tblApprovalDefinitionApprover_tblApprovalDefinitionVersion] FOREIGN KEY 
	(
		[fkApprovalDefinitionVersionID]
	) 
	REFERENCES [tblApprovalDefinitionVersion]
	(
		[pkID]
	),
	CONSTRAINT [FK_tblApprovalDefinitionApprover_tblLanguageBranch] FOREIGN KEY 
	(
		[fkLanguageBranchID]
	)
	REFERENCES [tblLanguageBranch]
	(
		[pkID]
	)
)

GO
PRINT N'Creating [IDX_tblApprovalDefinitionApprover_Username]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblApprovalDefinitionApprover_Username] ON [dbo].[tblApprovalDefinitionApprover] 
(
	[Username] ASC
)

GO
PRINT N'Creating [dbo].[tblApproval]...';


GO
CREATE TABLE [dbo].[tblApproval] (
	[pkID] INT IDENTITY (1,1) NOT NULL,
	[fkApprovalDefinitionVersionID] INT NOT NULL,
	[ApprovalKey] NVARCHAR (255) NOT NULL,
	[fkLanguageBranchID] INT NOT NULL,
	[ActiveStepIndex] INT NOT NULL,
	[ActiveStepStarted] DATETIME2 NOT NULL,
	[StepCount] INT NOT NULL,
	[StartedBy] NVARCHAR (255) NOT NULL,
	[Started] DATETIME2 NOT NULL,
	[Completed] DATETIME2 NULL,
	[ApprovalStatus] INT NOT NULL,
	CONSTRAINT [PK_tblApproval] PRIMARY KEY CLUSTERED 
	(
		[pkID] ASC
	),
	CONSTRAINT [FK_tblApproval_tblApprovalDefinitionVersion] FOREIGN KEY 
	(
		[fkApprovalDefinitionVersionID]
	) 
	REFERENCES [tblApprovalDefinitionVersion]
	(
		[pkID]
	), 
	CONSTRAINT [FK_tblApproval_tblLanguageBranch] FOREIGN KEY 
	(
		[fkLanguageBranchID]
	) 
	REFERENCES [tblLanguageBranch]
	(
		[pkID]
	)
)


GO
PRINT N'Creating [IDX_tblApproval_ApprovalKey]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblApproval_ApprovalKey] ON [dbo].[tblApproval] 
(
	[ApprovalKey] ASC
)

GO
PRINT N'Creating [IDX_tblApproval_ApprovalStatus]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblApproval_ApprovalStatus] ON [dbo].[tblApproval] 
(
	[ApprovalStatus] ASC
)


GO
PRINT N'Creating [dbo].[tblApprovalStepDecision]...';


GO
CREATE TABLE [dbo].[tblApprovalStepDecision] (
	[pkID] INT IDENTITY (1,1) NOT NULL,
	[fkApprovalID] INT NOT NULL,
	[StepIndex] INT NOT NULL,
	[Approve] BIT NOT NULL,
	[DecisionScope] INT NOT NULL,
	[Username] NVARCHAR (255) NOT NULL,
	[DecisionTimeStamp] DATETIME2 NOT NULL,
	CONSTRAINT [PK_tblApprovalStepDecision] PRIMARY KEY CLUSTERED 
	(
		[pkID] ASC
	),
	CONSTRAINT [FK_tblApprovalStepDecision_tblApproval] FOREIGN KEY (
		[fkApprovalID]
	) 
	REFERENCES [tblApproval]
	(
		[pkID]
	) 
	ON DELETE CASCADE
)


GO
PRINT N'Creating [AddApprovalDefinitionStepTable]...';


GO
CREATE TYPE [dbo].[AddApprovalDefinitionStepTable] AS TABLE(
	[StepIndex] INT NOT NULL,
	[StepName] NVARCHAR (255) NULL,
	[ApproversNeeded] INT NOT NULL
)


GO
PRINT N'Creating [dbo].[AddApprovalDefinitionApproverTable]...';


GO
CREATE TYPE [dbo].[AddApprovalDefinitionApproverTable] AS TABLE(
	[StepIndex] INT NOT NULL,
	[Username] NVARCHAR (255) NOT NULL,
	[fkLanguageBranchID] INT NOT NULL
)


GO
PRINT N'Creating [dbo].[AddApprovalTable]...';


GO
CREATE TYPE [dbo].[AddApprovalTable] AS TABLE(
	[ApprovalDefinitionVersionID] INT NOT NULL,
	[ApprovalKey] NVARCHAR(255) NOT NULL,
	[LanguageBranchID] INT NOT NULL
)


GO
PRINT N'Creating [dbo].[netApprovalDefinitionAddVersion]...';


GO
CREATE PROCEDURE [dbo].[netApprovalDefinitionAddVersion](
	@ApprovalDefinitionKey NVARCHAR (255),
	@SavedBy NVARCHAR (255),
	@Saved DATETIME2,
	@DemandCommentOnReject BIT,
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
	INSERT INTO [dbo].[tblApprovalDefinitionVersion]([fkApprovalDefinitionID], [SavedBy], [Saved], [DemandCommentOnReject], [IsEnabled]) OUTPUT inserted.pkID INTO @VersionIDTable VALUES (@ApprovalDefinitionID, @SavedBy, @Saved, @DemandCommentOnReject, @IsEnabled)
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
PRINT N'Creating [dbo].[netApprovalDefinitionDelete]...';


GO
CREATE PROCEDURE [dbo].[netApprovalDefinitionDelete](
	@ApprovalDefinitionID INT)
AS
BEGIN
	DECLARE @IDStatus TABLE (ID INT, [Status] INT)
	INSERT INTO @IDStatus
	SELECT a.pkID,a.ApprovalStatus FROM [dbo].[tblApproval] a 
	JOIN [dbo].[tblApprovalDefinitionVersion] v ON a.fkApprovalDefinitionVersionID = v.pkID 
	WHERE v.fkApprovalDefinitionID = @ApprovalDefinitionID

	IF NOT EXISTS(SELECT 1 FROM @IDStatus i WHERE i.[Status] = 0)  
	BEGIN 
		DELETE a FROM [dbo].[tblApproval] a 
		JOIN @IDStatus i ON a.pkID = i.ID
		WHERE i.[Status] != 0  
		
		DELETE FROM [dbo].[tblApprovalDefinition] WHERE pkID = @ApprovalDefinitionID
	END
END


GO
PRINT N'Creating [dbo].[netApprovalDefinitionVersionGet]...';


GO
CREATE PROCEDURE [dbo].[netApprovalDefinitionVersionGet](
	@ApprovalDefinitionVersionID INT)
AS
BEGIN
	SELECT [definition].* FROM [dbo].[tblApprovalDefinition] [definition] 
	JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON [definition].pkID = [version].fkApprovalDefinitionID
	WHERE [version].pkID = @ApprovalDefinitionVersionID
	
	SELECT * FROM [dbo].[tblApprovalDefinitionVersion] WHERE pkID = @ApprovalDefinitionVersionID 

	SELECT * FROM [dbo].[tblApprovalDefinitionStep] WHERE fkApprovalDefinitionVersionID = @ApprovalDefinitionVersionID ORDER BY StepIndex ASC

	SELECT * FROM [dbo].[tblApprovalDefinitionApprover]	WHERE fkApprovalDefinitionVersionID = @ApprovalDefinitionVersionID
END


GO
PRINT N'Creating [dbo].[netApprovalDefinitionGetCurrentVersion]...';


GO
CREATE PROCEDURE [dbo].[netApprovalDefinitionGetCurrentVersion](
	@ApprovalDefinitionID INT = NULL,
	@ApprovalDefinitionKey NVARCHAR (255) = NULL)
AS
BEGIN
	DECLARE @CurrentApprovalDefinitionVersionID INT
	IF @ApprovalDefinitionID IS NULL
		SELECT @CurrentApprovalDefinitionVersionID = fkCurrentApprovalDefinitionVersionID FROM [dbo].[tblApprovalDefinition] WHERE ApprovalDefinitionKey = @ApprovalDefinitionKey 
	ELSE
		SELECT @CurrentApprovalDefinitionVersionID = fkCurrentApprovalDefinitionVersionID FROM [dbo].[tblApprovalDefinition] WHERE pkID = @ApprovalDefinitionID
	
	EXEC [dbo].[netApprovalDefinitionVersionGet] @CurrentApprovalDefinitionVersionID
END


GO
PRINT N'Creating [dbo].[netApprovalDefinitionVersionDelete]...';


GO
CREATE PROCEDURE [dbo].[netApprovalDefinitionVersionDelete](
	@ApprovalDefinitionVersionID INT)
AS
BEGIN
	DECLARE @ApprovalDefinitionID INT 
	DECLARE @CurrentApprovalDefinitionVersionID INT 

	SELECT @CurrentApprovalDefinitionVersionID = [definition].fkCurrentApprovalDefinitionVersionID, @ApprovalDefinitionID = [definition].pkID
	FROM [dbo].[tblApprovalDefinition] [definition]
	JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON [definition].pkID = [version].fkApprovalDefinitionID
	WHERE [version].pkID = @ApprovalDefinitionVersionID

	IF NOT EXISTS(SELECT 1 FROM [dbo].[tblApproval] WHERE fkApprovalDefinitionVersionID = @ApprovalDefinitionVersionID AND ApprovalStatus = 0)
	BEGIN
		DELETE FROM [dbo].[tblApproval] WHERE fkApprovalDefinitionVersionID = @ApprovalDefinitionVersionID AND ApprovalStatus != 0 
		IF @ApprovalDefinitionVersionID = @CurrentApprovalDefinitionVersionID  
		BEGIN
			IF EXISTS(SELECT pkID FROM [dbo].[tblApprovalDefinitionVersion] WHERE fkApprovalDefinitionID = @ApprovalDefinitionID AND pkID != @ApprovalDefinitionVersionID)
			BEGIN
				UPDATE [dbo].[tblApprovalDefinition] SET fkCurrentApprovalDefinitionVersionID = NULL WHERE pkID = @ApprovalDefinitionID
				DELETE FROM [dbo].[tblApprovalDefinitionVersion] WHERE pkID = @ApprovalDefinitionVersionID
			END ELSE BEGIN 
				DELETE FROM [dbo].[tblApprovalDefinition] WHERE pkID = @ApprovalDefinitionID		
			END
		END ELSE BEGIN
			DELETE FROM [dbo].[tblApprovalDefinitionVersion] WHERE pkID = @ApprovalDefinitionVersionID
		END
	END
END

GO
PRINT N'Creating [dbo].[netApprovalDefinitionVersionList]...';


GO
CREATE PROCEDURE [dbo].[netApprovalDefinitionVersionList](
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
	
	SELECT approver.* FROM [dbo].[tblApprovalDefinitionApprover] approver 
	JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON approver.fkApprovalDefinitionVersionID = [version].pkID
	WHERE [version].fkApprovalDefinitionID = @ApprovalDefinitionID
END


GO
PRINT N'Creating [dbo].[netApprovalAdd]...';


GO
CREATE PROCEDURE [dbo].[netApprovalAdd](
	@StartedBy NVARCHAR(255),
	@Started DATETIME2,
	@Approvals [dbo].[AddApprovalTable] READONLY)
AS
BEGIN
	DELETE t FROM [dbo].[tblApproval] t
	JOIN @Approvals a ON t.ApprovalKey = a.ApprovalKey

	DECLARE @StepCounts AS TABLE(VersionID INT, StepCount INT)
	INSERT INTO @StepCounts
	SELECT VersionID, COUNT(*) AS StepCount FROM (
		SELECT DISTINCT adv.pkID AS VersionID, ads.pkID AS StepID FROM [dbo].[tblApprovalDefinitionVersion] adv
		JOIN [dbo].[tblApprovalDefinitionStep] ads ON adv.pkID = ads.fkApprovalDefinitionVersionID
		JOIN @Approvals approvals ON approvals.ApprovalDefinitionVersionID = adv.pkID
	) X	GROUP BY VersionID

	INSERT INTO [dbo].[tblApproval]([fkApprovalDefinitionVersionID], [ApprovalKey], [fkLanguageBranchID], [ActiveStepIndex], [ActiveStepStarted], [StepCount], [StartedBy], [Started], [Completed], [ApprovalStatus])
	SELECT a.ApprovalDefinitionVersionID, a.ApprovalKey, a.LanguageBranchID, 0, @Started, sc.StepCount, @StartedBy, @Started, NULL, 0 FROM @Approvals a
	JOIN @StepCounts sc ON a.ApprovalDefinitionVersionID = sc.VersionID

	SELECT t.ApprovalKey, t.pkID AS ApprovalID, t.StepCount FROM [dbo].[tblApproval] t
	JOIN @Approvals a ON t.ApprovalKey = a.ApprovalKey
END


GO
PRINT N'Creating [dbo].[netApprovalUpdate]...';


GO
CREATE PROCEDURE [dbo].[netApprovalUpdate](
	@ApprovalID INT,
	@ActiveStepIndex INT,
	@ActiveStepStarted DATETIME2,
	@Completed DATETIME2 = NULL,
	@ApprovalStatus INT)
AS
BEGIN
	UPDATE [dbo].[tblApproval] SET 
		[ActiveStepIndex] = @ActiveStepIndex,
		[ActiveStepStarted] = @ActiveStepStarted,
		[Completed] = @Completed,
		[ApprovalStatus] = @ApprovalStatus
	WHERE pkID = @ApprovalID
END


GO
PRINT N'Creating [dbo].[netApprovalStepDecisionAdd]...';


GO
CREATE PROCEDURE [dbo].[netApprovalStepDecisionAdd](
	@ApprovalID INT,
	@StepIndex INT,
	@Approve BIT,
	@DecisionScope INT,
	@Username NVARCHAR(255),
	@DecisionTimeStamp DATETIME2)
AS
BEGIN
	INSERT INTO [dbo].[tblApprovalStepDecision] ([fkApprovalID] ,[StepIndex] ,[Approve] ,[DecisionScope] ,[Username] ,[DecisionTimeStamp]) 
	VALUES (@ApprovalID, @StepIndex, @Approve, @DecisionScope, @Username, @DecisionTimeStamp)
END


GO
PRINT N'Creating [dbo].[netApprovalDelete]...';


GO
CREATE PROCEDURE [dbo].[netApprovalDelete](
	@ApprovalIDs [dbo].[IDTable] READONLY)
AS
BEGIN
	DELETE approval FROM [dbo].[tblApproval] approval 
	JOIN @ApprovalIDs ids ON approval.pkID = ids.ID
END


GO
PRINT N'Creating [dbo].[netApprovalList]...';


GO
CREATE PROCEDURE [dbo].[netApprovalList](
	@ApprovalIDs [dbo].[IDTable] READONLY)
AS
BEGIN
	SELECT approval.* FROM [dbo].[tblApproval] approval 
	JOIN @ApprovalIDs ids ON approval.pkID = ids.ID
END


GO
PRINT N'Creating [dbo].[netApprovalStepDecisionList]...';


GO
CREATE PROCEDURE [dbo].[netApprovalStepDecisionList](
	@ApprovalID INT,
	@StepIndex INT = NULL)
AS
BEGIN
	IF @StepIndex IS NULL
	BEGIN
		SELECT * FROM [dbo].[tblApprovalStepDecision] decision
		WHERE decision.fkApprovalID = @ApprovalID
		ORDER BY decision.StepIndex ASC
	END ELSE BEGIN
		SELECT * FROM [dbo].[tblApprovalStepDecision] decision
		WHERE decision.fkApprovalID = @ApprovalID AND decision.StepIndex = @StepIndex
	END
END


GO
PRINT N'Creating [dbo].[netApprovalListByKeys]...';


GO
CREATE PROCEDURE [dbo].[netApprovalListByKeys](
	@ApprovalKeys [dbo].[StringParameterTable] READONLY)
AS
BEGIN
	DECLARE @Count INT = (SELECT COUNT(*) FROM @ApprovalKeys)

	IF (@Count = 1)
	BEGIN
		DECLARE @ApprovalKey NVARCHAR(255) = (SELECT TOP 1 String + '%' FROM @ApprovalKeys) 
		SELECT approval.* FROM [dbo].[tblApproval] approval 
		WHERE approval.ApprovalKey LIKE @ApprovalKey
	END ELSE BEGIN
		SELECT approval.* FROM [dbo].[tblApproval] approval 
		JOIN @ApprovalKeys keys ON approval.ApprovalKey LIKE keys.String + '%'
	END
END


GO
PRINT N'Creating [dbo].[netApprovalListByQuery]...';


GO
CREATE PROCEDURE [dbo].[netApprovalListByQuery](
	@Username NVARCHAR(255) = NULL,
	@LanguageBranchID INT = NULL,
	@ApprovalKey NVARCHAR(255) = NULL,
	@DefinitionID INT = NULL,
	@Status INT = NULL,
	@OnlyActiveSteps BIT = 0)
AS
BEGIN
	DECLARE @JoinApprovalDefinitionVersion BIT = 0
	DECLARE @JoinApprovalDefinitionStep BIT = 0
	DECLARE @JoinApprovalDefinitionApprover BIT = 0
	DECLARE @JointblApprovalStepDecision BIT = 0
	
	IF @DefinitionID IS NOT NULL 
		SET @JoinApprovalDefinitionVersion = 1
	
	IF @Username IS NOT NULL
	BEGIN
		SET @JoinApprovalDefinitionVersion = 1
		SET @JoinApprovalDefinitionStep = 1
		SET @JoinApprovalDefinitionApprover = 1
		SET @JointblApprovalStepDecision = 1
	END

	DECLARE @SelectSql NVARCHAR(MAX) = 'SELECT DISTINCT [approval].* FROM [dbo].[tblApproval] [approval]' + CHAR(13); 

	IF @JoinApprovalDefinitionVersion = 1
		SET @SelectSql += 'JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON [approval].fkApprovalDefinitionVersionID = [version].pkID' + CHAR(13)

	IF @JoinApprovalDefinitionStep = 1           
		SET @SelectSql += 'JOIN [dbo].[tblApprovalDefinitionStep] [step] ON [step].fkApprovalDefinitionVersionID = [version].pkID' + CHAR(13)

	IF @JoinApprovalDefinitionApprover = 1		 
		SET @SelectSql += 'JOIN [dbo].[tblApprovalDefinitionApprover] [approver] ON [approver].fkApprovalDefinitionStepID = [step].pkID' + CHAR(13)

	IF @JointblApprovalStepDecision = 1			 
		SET @SelectSql += 'LEFT JOIN [dbo].[tblApprovalStepDecision] [decision] ON [approval].pkID = [decision].fkApprovalID' + CHAR(13)

	DECLARE @Wheres AS TABLE([String] NVARCHAR(MAX))

	IF @LanguageBranchID IS NOT NULL 
	BEGIN
		INSERT INTO @Wheres SELECT '[approval].fkLanguageBranchID = ' + CAST(@LanguageBranchID AS NVARCHAR(16))	
		IF @Username IS NOT NULL
		BEGIN
			DECLARE @InvariantLanguageBranchID INT = (SELECT [pkID] FROM [dbo].[tblLanguageBranch] WHERE LanguageID = '')
			IF @OnlyActiveSteps = 0
				INSERT INTO @Wheres SELECT '[approver].Username = @Username AND ([approver].fkLanguageBranchID = ' + CAST(@LanguageBranchID AS NVARCHAR(16)) + ' OR [approver].fkLanguageBranchID = ' + CAST(@InvariantLanguageBranchID AS NVARCHAR(16)) + ')'
			ELSE
				INSERT INTO @Wheres SELECT '[approval].ActiveStepIndex = [step].StepIndex AND [approver].Username = @Username AND ([approver].fkLanguageBranchID = ' + CAST(@LanguageBranchID AS NVARCHAR(16)) + ' OR [approver].fkLanguageBranchID = ' + CAST(@InvariantLanguageBranchID AS NVARCHAR(16)) + ')'
		END
	END

	IF @Status IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].ApprovalStatus = ' + CAST(@Status AS NVARCHAR(16))

	IF @DefinitionID IS NOT NULL 
		INSERT INTO @Wheres SELECT '[version].fkApprovalDefinitionID = ' + CAST(@DefinitionID AS NVARCHAR(16)) 

	IF @ApprovalKey IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].ApprovalKey LIKE @ApprovalKey + ''%''' 

	IF @Username IS NOT NULL
	BEGIN
		IF @OnlyActiveSteps = 0
			INSERT INTO @Wheres SELECT '([decision].Username = @Username OR [approver].Username = @Username)'
		ELSE
			INSERT INTO @Wheres SELECT '(([approval].ActiveStepIndex = [decision].StepIndex AND [decision].Username = @Username) OR ([approval].ActiveStepIndex = [step].StepIndex AND [approver].Username = @Username))'
	END

	DECLARE @WhereSql NVARCHAR(MAX) 
	SELECT @WhereSql = COALESCE(@WhereSql + CHAR(13) + 'AND ', '') + [String] FROM @Wheres

	DECLARE @Sql NVARCHAR(MAX) = @SelectSql 
	IF @WhereSql IS NOT NULL
		SET @Sql += 'WHERE ' + @WhereSql 
		
	EXEC sp_executesql @Sql, N'@Username NVARCHAR(255), @ApprovalKey NVARCHAR(255)', @Username = @Username, @ApprovalKey = @ApprovalKey
END


GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7038
GO

PRINT N'Update complete.';


GO

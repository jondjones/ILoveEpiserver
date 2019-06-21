--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7040)
				select 0, 'Already correct database version'
            else if (@ver = 7039)
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
	@Username NVARCHAR(255) = NULL,
	@StartedBy NVARCHAR(255) = NULL,
	@LanguageBranchID INT = NULL,
	@ApprovalKey NVARCHAR(255) = NULL,
	@DefinitionID INT = NULL,
	@DefinitionVersionID INT = NULL,
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

	IF @StartedBy IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].StartedBy = @StartedBy'

	IF @DefinitionVersionID IS NOT NULL 
		INSERT INTO @Wheres SELECT '[approval].fkApprovalDefinitionVersionID = ' + CAST(@DefinitionVersionID AS NVARCHAR(16))

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
		
	EXEC sp_executesql @Sql, N'@Username NVARCHAR(255), @StartedBy NVARCHAR(255), @ApprovalKey NVARCHAR(255)', @Username = @Username, @StartedBy = @StartedBy, @ApprovalKey = @ApprovalKey
END


GO
PRINT N'Altering [dbo].[tblApprovalStepDecision]...';


GO
ALTER TABLE [dbo].[tblApprovalStepDecision] 
ADD [Comment] NVARCHAR (MAX) NULL

GO
PRINT N'Altering [dbo].[tblApproval]...';


GO
ALTER TABLE [dbo].[tblApproval] 
ADD [CompletedComment] NVARCHAR (MAX) NULL
GO

ALTER TABLE [dbo].[tblApproval] 
ADD [CompletedBy] NVARCHAR (255) NULL

GO
PRINT N'Altering [dbo].[netApprovalUpdate]...';


GO
ALTER PROCEDURE [dbo].[netApprovalUpdate](
	@ApprovalID INT,
	@ActiveStepIndex INT,
	@ActiveStepStarted DATETIME2,
	@Completed DATETIME2 = NULL,
	@ApprovalStatus INT,
	@CompletedComment NVARCHAR(MAX) = NULL,
	@CompletedBy NVARCHAR(255) = NULL)
AS
BEGIN
	UPDATE [dbo].[tblApproval] SET 
		[ActiveStepIndex] = @ActiveStepIndex,
		[ActiveStepStarted] = @ActiveStepStarted,
		[Completed] = @Completed,
		[ApprovalStatus] = @ApprovalStatus,
		[CompletedComment] = @CompletedComment,
		[CompletedBy] = @CompletedBy
	WHERE pkID = @ApprovalID
END
GO
GO
PRINT N'Altering [dbo].[netApprovalStepDecisionAdd]...';

GO
ALTER PROCEDURE [dbo].[netApprovalStepDecisionAdd](
	@ApprovalID INT,
	@StepIndex INT,
	@Approve BIT,
	@DecisionScope INT,
	@Username NVARCHAR(255),
	@DecisionTimeStamp DATETIME2,
	@Comment NVARCHAR(MAX) = NULL
)
AS
BEGIN
	INSERT INTO [dbo].[tblApprovalStepDecision] ([fkApprovalID], [StepIndex], [Approve], [DecisionScope], [Username], [DecisionTimeStamp], [Comment]) 
	VALUES (@ApprovalID, @StepIndex, @Approve, @DecisionScope, @Username, @DecisionTimeStamp, @Comment)
END
GO

PRINT N'Dropping [dbo].[tblApproval].[IDX_tblApproval_ApprovalKey]...';
GO

DROP INDEX [IDX_tblApproval_ApprovalKey] ON [dbo].[tblApproval];
GO 

PRINT N'Dropping [dbo].[tblApproval].[IDX_tblApproval_ApprovalStatus]...';
GO

DROP INDEX [IDX_tblApproval_ApprovalStatus]  ON [dbo].[tblApproval];
GO 

PRINT N'Creating [dbo].[tblApproval].[IDX_tblApproval_ApprovalKeyAndStatus]...';
GO

CREATE NONCLUSTERED INDEX [IDX_tblApproval_ApprovalKeyAndStatus] ON [dbo].[tblApproval] 
(
	[ApprovalKey] ASC,
	[ApprovalStatus] ASC
)

PRINT N'Creating [dbo].[tblApproval].[IDX_tblApproval_fkApprovalDefinitionVersionID]...';
GO

CREATE NONCLUSTERED INDEX [IDX_tblApproval_fkApprovalDefinitionVersionID] ON [dbo].[tblApproval] 
(
	[fkApprovalDefinitionVersionID] ASC
)
GO

PRINT N'Creating [dbo].[tblApprovalDefinition].[IDX_tblApprovalDefinition_fkCurrentApprovalDefinitionVersionID]...';
GO

CREATE NONCLUSTERED INDEX [IDX_tblApprovalDefinition_fkCurrentApprovalDefinitionVersionID] ON [dbo].[tblApprovalDefinition] 
(
    [fkCurrentApprovalDefinitionVersionID] ASC
)
GO

PRINT N'Creating [dbo].[tblApprovalDefinitionApprover].[IDX_tblApprovalDefinitionApprover_fkApprovalDefinitionVersionID]...';
GO

CREATE NONCLUSTERED INDEX [IDX_tblApprovalDefinitionApprover_fkApprovalDefinitionVersionID] ON [dbo].[tblApprovalDefinitionApprover] 
(
    [fkApprovalDefinitionVersionID] ASC
)
GO

PRINT N'Creating [dbo].[tblApprovalDefinitionStep].[IDX_tblApprovalDefinitionStep_fkApprovalDefinitionVersionID]...';
GO

CREATE NONCLUSTERED INDEX [IDX_tblApprovalDefinitionStep_fkApprovalDefinitionVersionID] ON [dbo].[tblApprovalDefinitionStep] 
(
    [fkApprovalDefinitionVersionID] ASC
)
GO

PRINT N'Creating [dbo].[tblApprovalDefinitionVersion].[IDX_tblApprovalDefinitionVersion_fkApprovalDefinitionID]...';
GO

CREATE NONCLUSTERED INDEX [IDX_tblApprovalDefinitionVersion_fkApprovalDefinitionID] ON [dbo].[tblApprovalDefinitionVersion] 
(
    [fkApprovalDefinitionID] ASC
)
GO

PRINT N'Creating [dbo].[tblApprovalStepDecision].[IDX_tblApprovalStepDecision_fkApprovalID] ...';
GO

CREATE NONCLUSTERED INDEX [IDX_tblApprovalStepDecision_fkApprovalID] ON [dbo].[tblApprovalStepDecision] 
(
    [fkApprovalID] ASC
)
GO

-- BEGIN - Manually created update

ALTER TABLE [dbo].[tblScheduledItem] ADD [IsStoppable] [bit] NOT NULL CONSTRAINT [DF__tblScheduledItem__IsStoppable] DEFAULT (0) 
GO

ALTER TABLE [dbo].[tblScheduledItemLog] DROP 
	CONSTRAINT [fk_tblScheduledItemLog_tblScheduledItem];
GO

DECLARE @ExistingId UNIQUEIDENTIFIER;
SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Util.BlobCleanupJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{BBF2ECCD-2861-45F6-845C-B4D8CC5377DF}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{BBF2ECCD-2861-45F6-845C-B4D8CC5377DF}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Util.CleanUnusedAssetsFoldersJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{E652F3BD-F550-40E8-8743-2C39CDA651DC}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{E652F3BD-F550-40E8-8743-2C39CDA651DC}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Util.DelayedPublishJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{17F4A400-75E5-4449-A0AE-C44BFA50A213}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{17F4A400-75E5-4449-A0AE-C44BFA50A213}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Util.EmptyWastebasketJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{A42F6137-0BCF-4A88-BBD3-0EF219B7EAFA}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{A42F6137-0BCF-4A88-BBD3-0EF219B7EAFA}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Notification.Internal.NotificationDispatcherJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{4B61CDB6-CC46-417C-A1AD-A5020A32E1D3}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{4B61CDB6-CC46-417C-A1AD-A5020A32E1D3}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Notification.Internal.NotificationMessageTruncateJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{C9BAD721-5A61-4DF3-8EB9-A57FCB981CE1}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{C9BAD721-5A61-4DF3-8EB9-A57FCB981CE1}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Util.PageArchiveJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{63C7F148-12B1-4CDF-A2CA-8458208C6C26}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{63C7F148-12B1-4CDF-A2CA-8458208C6C26}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Util.TaskMonitorTruncateJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{9B72AF8B-A26D-4C68-9A1E-1DA242EDF6FD}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{9B72AF8B-A26D-4C68-9A1E-1DA242EDF6FD}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Util.ThumbnailPropertiesClearJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{F1B8E71C-5E6F-41C2-AB3E-D8FD85EF6C6D}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{F1B8E71C-5E6F-41C2-AB3E-D8FD85EF6C6D}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.LinkAnalyzer.LinkValidationJob' AND AssemblyName = 'EPiServer.LinkAnalyzer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{6BCE1827-F306-476A-B766-2B35838F6EA0}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{6BCE1827-F306-476A-B766-2B35838F6EA0}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Enterprise.Mirroring.MirroringManager' AND AssemblyName = 'EPiServer.Enterprise')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{8C503996-7759-41C1-8E34-EFD28F76BA76}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{8C503996-7759-41C1-8E34-EFD28F76BA76}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.ChangeLog.ChangeLogAutoTruncateJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{B32597BC-1A69-4095-B215-8FC6C1E5722A}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{B32597BC-1A69-4095-B215-8FC6C1E5722A}' WHERE fkScheduledItemId = @ExistingId
END

SET @ExistingId = (SELECT pkID FROM tblScheduledItem WHERE TypeName = 'EPiServer.Personalization.SubscriptionJob' AND AssemblyName = 'EPiServer')
IF (@ExistingId IS NOT NULL)
BEGIN
	UPDATE tblScheduledItem SET pkID = '{E2D25A3B-09F2-4209-9760-77CCBB5097E0}' WHERE pkID = @ExistingId
	UPDATE tblScheduledItemLog SET fkScheduledItemId = '{E2D25A3B-09F2-4209-9760-77CCBB5097E0}' WHERE fkScheduledItemId = @ExistingId
END
GO

ALTER TABLE [dbo].[tblScheduledItemLog] ADD 
	CONSTRAINT [fk_tblScheduledItemLog_tblScheduledItem] FOREIGN KEY 
	(
		[fkScheduledItemId]
	) REFERENCES [dbo].[tblScheduledItem] (
		[pkID]
	)

-- END - Manually created update
GO
PRINT N'Dropping [dbo].[netSchedulerGetNext]...';

GO
DROP PROCEDURE [dbo].[netSchedulerGetNext];


GO
PRINT N'Dropping [dbo].[netSchedulerLoadJob]...';


GO
DROP PROCEDURE [dbo].[netSchedulerLoadJob];


GO
PRINT N'Altering [dbo].[tblScheduledItem]...';


GO
ALTER TABLE [dbo].[tblScheduledItem] ALTER COLUMN [LastText] NVARCHAR (MAX) NULL;


GO
PRINT N'Altering [dbo].[tblScheduledItemLog]...';


GO
ALTER TABLE [dbo].[tblScheduledItemLog] ALTER COLUMN [Text] NVARCHAR (MAX) NULL;


GO
ALTER TABLE [dbo].[tblScheduledItemLog]
    ADD [Duration] BIGINT         NULL,
        [Server]   NVARCHAR (255) NULL,
        [Trigger]  INT            NULL;


GO
PRINT N'Altering [dbo].[netSchedulerExecute]...';


GO
ALTER PROCEDURE dbo.netSchedulerExecute
(
	@pkID        uniqueidentifier,
	@currentExec datetime,
	@updatedExec datetime,
	@pingSeconds int,
	@updated	 bit out
)
AS
BEGIN
	SET NOCOUNT ON

	/**
	 * is the scheduled nextExec still valid? 
	 * (that is, no one else has already begun executing it?)
	 */
	IF EXISTS(SELECT * FROM tblScheduledItem WITH (rowlock,updlock) WHERE pkID = @pkID AND NextExec = @currentExec AND Enabled = 1 AND (IsRunning <> 1 OR (GETUTCDATE() > DATEADD(second, @pingSeconds, LastPing))) )
	BEGIN
		UPDATE tblScheduledItem SET NextExec = @updatedExec FROM tblScheduledItem WHERE pkID = @pkID
		SET @updated = 1
	END
	ELSE
	BEGIN
		SET @updated = 0
	END
END
GO
PRINT N'Altering [dbo].[netSchedulerReport]...';


GO
ALTER PROCEDURE [dbo].[netSchedulerReport]
@ScheduledItemId UNIQUEIDENTIFIER,
@Status INT,
@Text	NVARCHAR(MAX) = null,
@ExecutionCompleted DATETIME,
@MaxHistoryCount	INT = NULL,
@Duration BIGINT = NULL,
@Trigger INT = NULL,
@Server NVARCHAR(255) = NULL
AS
BEGIN

	UPDATE tblScheduledItem SET LastExec = @ExecutionCompleted,
								LastStatus = @Status,
								LastText = @Text
	FROM tblScheduledItem
	WHERE pkID = @ScheduledItemId

	INSERT INTO tblScheduledItemLog( fkScheduledItemId, [Exec], Status, [Text], [Duration], [Trigger], [Server]) 
		VALUES(@ScheduledItemId,@ExecutionCompleted,@Status,@Text, @Duration, @Trigger, @Server)

	WHILE (SELECT COUNT(pkID) FROM tblScheduledItemLog WHERE fkScheduledItemId = @ScheduledItemId) > @MaxHistoryCount
	BEGIN
		DELETE tblScheduledItemLog FROM (SELECT TOP 1 * FROM tblScheduledItemLog WHERE fkScheduledItemId = @ScheduledItemId ORDER BY tblScheduledItemLog.pkID) AS T1
		WHERE tblScheduledItemLog.pkID = T1.pkID
	END	
END
GO
PRINT N'Altering [dbo].[netSchedulerListLog]...';


GO
ALTER PROCEDURE [dbo].netSchedulerListLog
(
	@pkID UNIQUEIDENTIFIER,
	@startIndex BIGINT = NULL,
	@maxCount INT = NULL
)
AS
BEGIN
	DECLARE @TotalCount BIGINT = (SELECT COUNT(*) FROM tblScheduledItemLog WHERE fkScheduledItemId = @pkID)

	;WITH Items_CTE AS
	(
		SELECT [Exec], [Status], [Text], [Duration], [Trigger], [Server], ROW_NUMBER() OVER (ORDER BY [Exec] DESC) AS [RowIndex]
		FROM tblScheduledItemLog
		WHERE fkScheduledItemId = @pkID
	)
	SELECT TOP (@maxCount) [Exec], Status, [Text], [Duration], [Trigger], [Server], @TotalCount AS 'TotalCount'
	FROM Items_CTE
	WHERE RowIndex >= @startIndex
END
GO
PRINT N'Altering [dbo].[netSchedulerList]...';


GO
ALTER PROCEDURE [dbo].netSchedulerList
AS
BEGIN

	SELECT CONVERT(NVARCHAR(40),pkID) AS pkID,Name,CONVERT(INT,Enabled) AS Enabled,LastExec,LastStatus,LastText,NextExec,[DatePart],Interval,MethodName,CONVERT(INT,fStatic) AS fStatic,TypeName,AssemblyName,InstanceData, IsRunning, CurrentStatusMessage, DateDiff(second, LastPing, GETUTCDATE()) as SecondsAfterLastPing, IsStoppable
	FROM tblScheduledItem
	ORDER BY Name ASC

END
GO
PRINT N'Altering [dbo].[netSchedulerSave]...';

GO

ALTER PROCEDURE [dbo].netSchedulerSave
(
@pkID		UNIQUEIDENTIFIER,
@Name		NVARCHAR(50),
@Enabled	BIT = 0,
@NextExec 	DATETIME,
@DatePart	NCHAR(2) = NULL,
@Interval	INT = 0,
@MethodName NVARCHAR(100),
@fStatic 	BIT,
@TypeName 	NVARCHAR(1024),
@AssemblyName NVARCHAR(100),
@InstanceData	IMAGE = NULL,
@IsStoppable BIT = 0
)
AS
BEGIN

IF EXISTS(SELECT * FROM tblScheduledItem WHERE pkID=@pkID)
	UPDATE tblScheduledItem SET
		Name 		= @Name,
		Enabled 	= @Enabled,
		NextExec 	= @NextExec,
		[DatePart] 	= @DatePart,
		Interval 		= @Interval,
		MethodName 	= @MethodName,
		fStatic 		= @fStatic,
		TypeName 	= @TypeName,
		AssemblyName 	= @AssemblyName,
		InstanceData	= @InstanceData,
		IsStoppable = @IsStoppable
	WHERE pkID = @pkID
ELSE
	INSERT INTO tblScheduledItem(pkID,Name,Enabled,NextExec,[DatePart],Interval,MethodName,fStatic,TypeName,AssemblyName,InstanceData,IsStoppable)
	VALUES(@pkID,@Name,@Enabled,@NextExec,@DatePart,@Interval, @MethodName,@fStatic,@TypeName,@AssemblyName,@InstanceData, @IsStoppable)


END

GO
PRINT N'Updating [dbo].[tblApprovalDefinition].[ApprovalDefinitionKey]...';

GO

DECLARE @tblApprovalDefinitionKeyConverter AS TABLE(ID INT, [Key] [NVARCHAR](255), Index1 INT, Index2 INT, Index3 INT, Index4 INT)
INSERT INTO @tblApprovalDefinitionKeyConverter(ID,[Key])
SELECT pkID, ApprovalDefinitionKey + '___'  FROM [dbo].[tblApprovalDefinition] WHERE ApprovalDefinitionKey LIKE 'content:%' AND ApprovalDefinitionKey NOT LIKE '%/%'

UPDATE @tblApprovalDefinitionKeyConverter SET Index1 = CHARINDEX(':',[Key], 0) + 1
UPDATE @tblApprovalDefinitionKeyConverter SET Index2 = CHARINDEX('_',[Key], Index1) + 1
UPDATE @tblApprovalDefinitionKeyConverter SET Index3 = CHARINDEX('_',[Key], Index2) + 1
UPDATE @tblApprovalDefinitionKeyConverter SET Index4 = CHARINDEX('_',[Key], Index3) + 1

UPDATE t1 
SET ApprovalDefinitionKey = Content + ProviderName + '/' + ContentID + '/' + CASE WorkID WHEN '' THEN '' ELSE WorkID + '/' END 
FROM [dbo].[tblApprovalDefinition] t1 
JOIN (
	SELECT 
		ID,
		SUBSTRING([Key], 0, Index1) AS Content,
		SUBSTRING([Key], Index1, Index2 - Index1 - 1) AS ContentID, 
		SUBSTRING([Key], Index2, Index3 - Index2 - 1) AS WorkID,
		SUBSTRING([Key], Index3, Index4 - Index3 - 1) AS ProviderName
	FROM @tblApprovalDefinitionKeyConverter) t2 ON t1.pkID = t2.ID


GO
PRINT N'Updating [dbo].[tblApproval].[ApprovalKey]...';

GO

DECLARE @tblApprovalKeyConverter AS TABLE(ID INT, [Key] [NVARCHAR](255), Index1 INT, Index2 INT, Index3 INT, Index4 INT)
INSERT INTO @tblApprovalKeyConverter(ID,[Key])
SELECT pkID, ApprovalKey + '___'  FROM [dbo].[tblApproval] WHERE ApprovalKey LIKE 'content:%' AND ApprovalKey NOT LIKE '%/%'

UPDATE @tblApprovalKeyConverter SET Index1 = CHARINDEX(':',[Key], 0) + 1
UPDATE @tblApprovalKeyConverter SET Index2 = CHARINDEX('_',[Key], Index1) + 1
UPDATE @tblApprovalKeyConverter SET Index3 = CHARINDEX('_',[Key], Index2) + 1
UPDATE @tblApprovalKeyConverter SET Index4 = CHARINDEX('_',[Key], Index3) + 1

UPDATE t1 
SET ApprovalKey = Content + ProviderName + '/' + ContentID + '/' + CASE WorkID WHEN '' THEN '' ELSE WorkID + '/' END 
FROM [dbo].[tblApproval] t1 
JOIN (
	SELECT 
		ID,
		SUBSTRING([Key], 0, Index1) AS Content,
		SUBSTRING([Key], Index1, Index2 - Index1 - 1) AS ContentID, 
		SUBSTRING([Key], Index2, Index3 - Index2 - 1) AS WorkID,
		SUBSTRING([Key], Index3, Index4 - Index3 - 1) AS ProviderName
	FROM @tblApprovalKeyConverter) t2 ON t1.pkID = t2.ID

GO


PRINT N'Updating tblScheduledItemLog Status';
UPDATE [dbo].[tblScheduledItemLog] SET [Status] = [Status] + 1 WHERE [Status] IS NOT NULL 
GO

PRINT N'Updating tblScheduledItem LastStatus';
UPDATE [dbo].[tblScheduledItem] SET [LastStatus] = [LastStatus] + 1 WHERE [LastStatus] IS NOT NULL  
GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7040
GO

PRINT N'Update complete.';
GO

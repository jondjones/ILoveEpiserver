--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7046)
				select 0, 'Already correct database version'
            else if (@ver = 7045)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
GO

PRINT N'Altering [dbo].[BigTableDeleteExcessReferences]...';
GO
ALTER PROCEDURE [dbo].[BigTableDeleteExcessReferences]
	@Id bigint,
	@PropertyName nvarchar(75),
	@StartIndex int
AS
BEGIN
BEGIN TRAN
	IF @StartIndex > -1
	BEGIN
		-- Creates temporary store with id's of references that has no other reference
		DECLARE @deletes AS BigTableDeleteItemInternalTable;
		
		INSERT INTO @deletes(Id, NestLevel, ObjectPath)
        SELECT DISTINCT R1.RefIdValue, 1, '/' + CAST(R1.RefIdValue AS VARCHAR) + '/' FROM tblBigTableReference AS R1
        LEFT OUTER JOIN tblBigTableReference AS R2 ON R1.RefIdValue = R2.pkId
        WHERE R1.pkId = @Id AND R1.PropertyName = @PropertyName AND R1.[Index] >= @StartIndex AND R2.RefIdValue IS NULL

		DELETE FROM @deletes WHERE Id IS NULL --Avoid filtering on NULL above to minimize deadlock risk

		-- Remove reference on main store
		DELETE FROM tblBigTableReference WHERE pkId = @Id and PropertyName = @PropertyName and [Index] >= @StartIndex
		
		IF((select count(*) from @deletes) > 0)
		BEGIN
			EXEC sp_executesql N'BigTableDeleteItemInternal @deletes', N'@deletes BigTableDeleteItemInternalTable READONLY',@deletes 
		END

	END
	ELSE
		-- Remove reference on main store
		DELETE FROM tblBigTableReference WHERE pkId = @Id and PropertyName = @PropertyName and [Index] >= @StartIndex
COMMIT TRAN

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

		INSERT INTO tblActivityLogAssociation([To], [From])
		SELECT @Id, Source.String
		FROM @Associations AS Source
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

		MERGE tblActivityLogAssociation AS TARGET
		USING @Associations AS Source
		ON (Target.[To] = @Id AND Target.[From] = Source.String)
		WHEN NOT MATCHED BY Target THEN
			INSERT ([To], [From])
			VALUES (@Id, Source.String);
	END
END
GO

PRINT N'Altering [dbo].[tblApproval]...';

GO
ALTER TABLE [dbo].[tblApproval]
    ADD [RequireCommentOnApprove] BIT NULL,
        [RequireCommentOnReject]  BIT NULL;

GO
PRINT N'Updating [dbo].[tblApproval]...';

GO

UPDATE a 
SET a.RequireCommentOnApprove = adv.RequireCommentOnApprove, a.RequireCommentOnReject = adv.RequireCommentOnReject
FROM tblApproval a
JOIN tblApprovalDefinitionVersion adv on a.fkApprovalDefinitionVersionID = adv.pkID

GO
PRINT N'Altering [dbo].[tblApproval]...';

GO
ALTER TABLE [dbo].[tblApproval] ALTER COLUMN [RequireCommentOnApprove] BIT NOT NULL
ALTER TABLE [dbo].[tblApproval] ALTER COLUMN [RequireCommentOnReject] BIT NOT NULL

GO
PRINT N'Altering [dbo].[netApprovalAdd]...';


GO
ALTER PROCEDURE [dbo].[netApprovalAdd](
	@StartedBy NVARCHAR(255),
	@Started DATETIME2,
	@Approvals [dbo].[AddApprovalTable] READONLY)
AS
BEGIN
	DELETE t FROM [dbo].[tblApproval] t
	JOIN @Approvals a ON t.ApprovalKey = a.ApprovalKey

	DECLARE @StepCounts AS TABLE(VersionID INT, StepCount INT, RequireCommentOnApprove BIT, RequireCommentOnReject BIT)

	INSERT INTO @StepCounts
	SELECT VersionID, COUNT(*) AS StepCount, RequireCommentOnApprove, RequireCommentOnReject FROM (
		SELECT DISTINCT adv.pkID AS VersionID, ads.pkID AS StepID, adv.RequireCommentOnApprove, adv.RequireCommentOnReject FROM [dbo].[tblApprovalDefinitionVersion] adv
		JOIN [dbo].[tblApprovalDefinitionStep] ads ON adv.pkID = ads.fkApprovalDefinitionVersionID
		JOIN @Approvals approvals ON approvals.ApprovalDefinitionVersionID = adv.pkID
	) X	GROUP BY VersionID, RequireCommentOnApprove, RequireCommentOnReject

	INSERT INTO [dbo].[tblApproval]([fkApprovalDefinitionVersionID], [ApprovalKey], [fkLanguageBranchID], [ActiveStepIndex], [ActiveStepStarted], [StepCount], [StartedBy], [Started], [Completed], [ApprovalStatus], [RequireCommentOnApprove], [RequireCommentOnReject])
	SELECT a.ApprovalDefinitionVersionID, a.ApprovalKey, a.LanguageBranchID, 0, @Started, sc.StepCount, @StartedBy, @Started, NULL, 0, sc.RequireCommentOnApprove, sc.RequireCommentOnReject FROM @Approvals a
	JOIN @StepCounts sc ON a.ApprovalDefinitionVersionID = sc.VersionID

	SELECT t.ApprovalKey, t.pkID AS ApprovalID, t.StepCount, t.RequireCommentOnApprove, t.RequireCommentOnReject FROM [dbo].[tblApproval] t
	JOIN @Approvals a ON t.ApprovalKey = a.ApprovalKey
END
GO

PRINT N'Altering [dbo].[tblScheduledItem]...';
GO

ALTER TABLE [dbo].[tblScheduledItem]
	ADD [LastExecutionAttempt] INT NOT NULL DEFAULT (0) , 
    [Restartable] BIT NOT NULL DEFAULT (0)
GO


PRINT N'Altering [dbo].[netSchedulerExecute]...';
GO

ALTER  PROCEDURE [dbo].[netSchedulerExecute]
(
	@pkID        uniqueidentifier,
	@currentExec datetime,
	@updatedExec datetime,
	@pingSeconds int,
	@expectedExecutionAttempt int,
	@nextExecutionAttempt int,
	@updated	 bit out 
)
AS
BEGIN
	SET NOCOUNT ON

	IF EXISTS(SELECT * FROM tblScheduledItem WITH (rowlock, updlock) WHERE pkID = @pkID AND NextExec = @currentExec AND LastExecutionAttempt = @expectedExecutionAttempt AND Enabled = 1 AND (IsRunning <> 1 OR (GETUTCDATE() > DATEADD(second, @pingSeconds, LastPing))))
	BEGIN
		UPDATE tblScheduledItem SET 
			NextExec = @updatedExec, 
			LastExecutionAttempt = @nextExecutionAttempt, 
			LastPing = GETUTCDATE(),
			IsRunning = 1  
		WHERE 
			pkID = @pkID

		SET @updated = 1
	END
	ELSE
		SET @updated = 0

END
GO

PRINT N'Altering [dbo].[netSchedulerList]...';
GO

ALTER PROCEDURE [dbo].[netSchedulerList]
AS
BEGIN

	SELECT CONVERT(NVARCHAR(40),pkID) AS pkID,Name,CONVERT(INT,Enabled) AS Enabled,LastExec,LastStatus,LastText,NextExec,[DatePart],Interval,MethodName,CONVERT(INT,fStatic) AS fStatic,TypeName,AssemblyName,InstanceData, IsRunning, CurrentStatusMessage, DateDiff(second, LastPing, GETUTCDATE()) as SecondsAfterLastPing, IsStoppable, Restartable, LastExecutionAttempt
	FROM tblScheduledItem
	ORDER BY Name ASC

END
GO


PRINT N'Altering [dbo].[netSchedulerSave]...';
GO

ALTER PROCEDURE [dbo].[netSchedulerSave]
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
@IsStoppable BIT = 0,
@Restartable    INT = 0
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
		IsStoppable = @IsStoppable,
		Restartable		= @Restartable
	WHERE pkID = @pkID
ELSE
	INSERT INTO tblScheduledItem(pkID,Name,Enabled,NextExec,[DatePart],Interval,MethodName,fStatic,TypeName,AssemblyName,InstanceData,IsStoppable,Restartable)
	VALUES(@pkID,@Name,@Enabled,@NextExec,@DatePart,@Interval, @MethodName,@fStatic,@TypeName,@AssemblyName,@InstanceData, @IsStoppable, @Restartable)
END
GO


PRINT N'Altering [dbo].[netSchedulerSetRunningState]...';
GO

ALTER PROCEDURE dbo.netSchedulerSetRunningState
	@pkID UNIQUEIDENTIFIER,
	@IsRunning bit,
	@resetLastExecutionAttempt bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN
	    UPDATE tblScheduledItem SET
				IsRunning = @IsRunning, 
				LastPing = GETUTCDATE(), 
				CurrentStatusMessage = NULL, 
				LastExecutionAttempt =  CASE @resetLastExecutionAttempt WHEN 1 THEN 0 ELSE ISNULL(LastExecutionAttempt, 0) END
		WHERE 
				pkID = @pkID
	END	
END
GO

ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7046
GO

PRINT N'Update complete.';
GO

--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7047)
				select 0, 'Already correct database version'
            else if (@ver = 7046)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
GO

PRINT N'Altering [dbo].[netSchedulerReport]...';
GO

ALTER PROCEDURE [dbo].[netSchedulerReport]
(
	@ScheduledItemId UNIQUEIDENTIFIER,
	@Status INT,
	@Text	NVARCHAR(MAX) = null,
	@ExecutionCompleted DATETIME,
	@Duration BIGINT = NULL,
	@Trigger INT = NULL,
	@Server NVARCHAR(255) = NULL
)
AS
BEGIN

	UPDATE tblScheduledItem SET LastExec = @ExecutionCompleted,
								LastStatus = @Status,
								LastText = @Text
	FROM tblScheduledItem
	WHERE pkID = @ScheduledItemId

	INSERT INTO tblScheduledItemLog( fkScheduledItemId, [Exec], Status, [Text], [Duration], [Trigger], [Server]) 
		VALUES(@ScheduledItemId,@ExecutionCompleted,@Status,@Text, @Duration, @Trigger, @Server)

END
GO


PRINT N'Creating [dbo].[netSchedulerTruncateLog]...';
GO


CREATE PROCEDURE [dbo].[netSchedulerTruncateLog]
(
	@ScheduledItemId UNIQUEIDENTIFIER,
	@MaxHistoryCount	INT = NULL
)
AS
BEGIN

   DECLARE @MaxCount int = 0 
   SELECT  @MaxCount = COUNT(pkID) FROM tblScheduledItemLog WITH(NOLOCK) WHERE fkScheduledItemId = @ScheduledItemId 

   IF(@MaxCount > @MaxHistoryCount)
   BEGIN
		  DELETE
		  FROM tblScheduledItemLog 
		  WHERE pkID IN (SELECT TOP(@MaxCount - @MaxHistoryCount) pkID FROM tblScheduledItemLog WHERE fkScheduledItemId =  @ScheduledItemId ORDER BY pkID ASC)
   END

END
GO

ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7047
GO

PRINT N'Update complete.';
GO

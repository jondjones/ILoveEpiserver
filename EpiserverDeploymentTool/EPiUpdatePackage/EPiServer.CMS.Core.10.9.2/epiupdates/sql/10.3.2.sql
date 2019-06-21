--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7041)
				select 0, 'Already correct database version'
            else if (@ver = 7040)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
GO

PRINT N'Altering [dbo].[ChangeNotificationAccessConnectionWorker]...';
GO

ALTER PROCEDURE [dbo].[ChangeNotificationAccessConnectionWorker]
    @connectionId uniqueidentifier,
    @expectedChangeNotificationDataType nvarchar(30) = null
as
begin
    declare @processorId uniqueidentifier
    declare @queuedDataType nvarchar(30)
    declare @processorStatus nvarchar(30)
    declare @nextQueueOrderValue int
    declare @lastConsistentDbUtc datetime
    declare @isOpen bit

    select @processorId = p.ProcessorId, @queuedDataType = p.ChangeNotificationDataType, @processorStatus = p.ProcessorStatus, @nextQueueOrderValue = p.NextQueueOrderValue, @lastConsistentDbUtc = p.LastConsistentDbUtc, @isOpen = c.IsOpen
    from tblChangeNotificationProcessor p
    join tblChangeNotificationConnection c on p.ProcessorId = c.ProcessorId
    where c.ConnectionId = @connectionId

    if (@processorId is null)
    begin
        set @processorStatus = 'closed'
    end
    else if (@expectedChangeNotificationDataType is not null and @expectedChangeNotificationDataType != @queuedDataType)
    begin
        set @processorStatus = 'type_mismatch'
    end
    else if (@processorStatus = 'invalid' or @isOpen = 1)
    begin
        -- the queue is invalid, or the current connection is valid.
        -- all pending connection requests may be considered open.
        update tblChangeNotificationConnection
        set IsOpen = 1
        where ProcessorId = @processorId and IsOpen = 0

        if (@processorStatus = 'valid' and @nextQueueOrderValue = 0)
        begin
            set @lastConsistentDbUtc = GETUTCDATE()
        end
    end
    else if (@isOpen = 0 and @processorStatus != 'invalid')
    begin
        set @processorStatus = 'opening'
    end

    update tblChangeNotificationConnection
    set LastActivityDbUtc = GETUTCDATE()
    where ConnectionId = @connectionId

    select @processorId as ProcessorId,  @processorStatus as ProcessorStatus, @lastConsistentDbUtc
end

GO

PRINT N'Altering [dbo].[netSchedulerListLog]...';
GO

ALTER PROCEDURE [dbo].netSchedulerListLog
(
	@pkID UNIQUEIDENTIFIER,
	@startIndex BIGINT = 0,
	@maxCount INT = 100
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

PRINT N'Altering [dbo].[netApprovalDefinitionDelete]...';


GO
ALTER PROCEDURE [dbo].[netApprovalDefinitionDelete](
	@ApprovalDefinitionIDs [dbo].[IDTable] READONLY)
AS
BEGIN
	DECLARE @IDStatus TABLE (ID INT, [Status] INT)
	INSERT INTO @IDStatus
	SELECT a.pkID,a.ApprovalStatus FROM [dbo].[tblApproval] a 
	JOIN [dbo].[tblApprovalDefinitionVersion] v ON a.fkApprovalDefinitionVersionID = v.pkID 
	JOIN @ApprovalDefinitionIDs ids ON v.fkApprovalDefinitionID = ids.ID

	IF NOT EXISTS(SELECT 1 FROM @IDStatus i WHERE i.[Status] = 0)  
	BEGIN 
		DELETE a FROM [dbo].[tblApproval] a 
		JOIN @IDStatus i ON a.pkID = i.ID
		WHERE i.[Status] != 0  

		DELETE [definition] FROM [dbo].[tblApprovalDefinition] [definition]
		JOIN @ApprovalDefinitionIDs ids ON [definition].pkID = ids.ID
	END
END


GO
PRINT N'Altering [dbo].[netApprovalDefinitionGetCurrentVersion]...';


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
	
	SELECT approver.* FROM [dbo].[tblApprovalDefinitionApprover] approver 
	JOIN [dbo].[tblApprovalDefinitionVersion] [version] ON approver.fkApprovalDefinitionVersionID = [version].pkID
	JOIN @ApprovalDefinitionVersionIDs [versionid] ON [version].pkID = versionid.ID 
END


GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7041
GO

PRINT N'Update complete.';
GO

--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7033)
				select 0, 'Already correct database version'
            else if (@ver = 7032)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
GO

PRINT N'Creating [dbo].[netNotificationMessageList]...';
GO

ALTER PROCEDURE [dbo].[netNotificationMessageList]
	@Recipient NVARCHAR(50) = NULL,
	@Channel NVARCHAR(50) = NULL,
	@Category NVARCHAR(255) = NULL,
	@Read BIT = NULL,
	@Sent BIT = NULL,
	@StartIndex	INT,
	@MaxCount	INT
AS
BEGIN
	DECLARE @Ids AS TABLE([RowNr] [int] IDENTITY(0,1), [ID] [bigint] NOT NULL)

	INSERT INTO @Ids
	SELECT pkID
	FROM [tblNotificationMessage]
	WHERE
		((@Recipient IS NULL) OR (@Recipient = Recipient))
		AND
		((@Channel IS NULL) OR (@Channel = Channel))
		AND
		((@Category IS NULL) OR (Category LIKE @Category + '%'))
		AND
		(@Read IS NULL OR 
			((@Read = 1 AND [Read] IS NOT NULL) OR
			(@Read = 0 AND [Read] IS NULL)))
		AND
		(@Sent IS NULL OR 
			((@Sent = 1 AND [Sent] IS NOT NULL) OR
			(@Sent = 0 AND [Sent] IS NULL)))
	ORDER BY Saved DESC

	DECLARE @TotalCount INT = (SELECT COUNT(*) FROM @Ids)
 
	SELECT TOP(@MaxCount) pkID AS ID, [Recipient], [Sender], [Channel], [Type], [Subject], [Content], [Sent], [SendAt], [Saved], [Read], [Category], @TotalCount AS 'TotalCount'
	FROM [tblNotificationMessage] nm
	JOIN @Ids ids ON nm.[pkID] = ids.[ID]
	WHERE ids.RowNr >= @StartIndex
	ORDER BY nm.[Saved] DESC
END
GO

ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7033
GO

PRINT N'Update complete.';
GO

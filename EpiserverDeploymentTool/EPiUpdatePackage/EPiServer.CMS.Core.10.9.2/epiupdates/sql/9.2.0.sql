--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7027)
				select 0, 'Already correct database version'
            else if (@ver = 7026)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO

PRINT N'Creating [dbo].[tblNotificationSubscription]...';
GO

CREATE TABLE [dbo].[tblNotificationSubscription](
	[pkID] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [nvarchar](50) NOT NULL,
	[SubscriptionKey] [nvarchar](255) NOT NULL,
	[Active] BIT NOT NULL DEFAULT 1
	CONSTRAINT [PK_tblNotificationSubscription] PRIMARY KEY CLUSTERED([pkID]), 
)
GO

PRINT N'Creating [dbo].[tblNotificationSubscription].[IDX_tblNotificationSubscription_UserName]...';
GO

CREATE NONCLUSTERED INDEX [IDX_tblNotificationSubscription_UserName]
    ON [dbo].[tblNotificationSubscription]([UserName] ASC);
GO

PRINT N'Creating [dbo].[tblNotificationSubscription].[IDX_tblNotificationSubscription_SubscriptionKey]...';
GO

CREATE NONCLUSTERED INDEX [IDX_tblNotificationSubscription_SubscriptionKey]
    ON [dbo].[tblNotificationSubscription]([SubscriptionKey] ASC);
GO

PRINT N'Creating [dbo].[netNotificationSubscriptionSubscribe]...';
GO

CREATE PROCEDURE [dbo].[netNotificationSubscriptionSubscribe]
	@UserName [nvarchar](50),
	@SubscriptionKey [nvarchar](255)
AS
BEGIN
	DECLARE @SubscriptionCount INT 
	SELECT @SubscriptionCount = COUNT(*) FROM [dbo].[tblNotificationSubscription] WHERE UserName = @UserName AND SubscriptionKey = @SubscriptionKey AND Active = 1
	IF (@SubscriptionCount > 0)
	BEGIN
		SELECT 0
		RETURN
	END
	SELECT @SubscriptionCount = COUNT(*) FROM [dbo].[tblNotificationSubscription] WHERE UserName = @UserName AND SubscriptionKey = @SubscriptionKey AND Active = 0
	IF (@SubscriptionCount > 0)
		UPDATE [dbo].[tblNotificationSubscription] SET Active = 1 WHERE UserName = @UserName AND SubscriptionKey = @SubscriptionKey
	ELSE 
		INSERT INTO [dbo].[tblNotificationSubscription](UserName, SubscriptionKey) VALUES (@UserName, @SubscriptionKey)	
	SELECT 1
END
GO

PRINT N'Creating [dbo].[netNotificationSubscriptionUnsubscribe]...';
GO

CREATE PROCEDURE [dbo].[netNotificationSubscriptionUnsubscribe]
	@UserName [nvarchar](50),
	@SubscriptionKey [nvarchar](255)
AS
BEGIN
	DECLARE @SubscriptionCount INT = (SELECT COUNT(*) FROM [dbo].[tblNotificationSubscription] WHERE UserName = @UserName AND SubscriptionKey = @SubscriptionKey AND Active = 1)
	DECLARE @Result INT = CASE @SubscriptionCount WHEN 0 THEN 0 ELSE 1 END
	IF (@SubscriptionCount > 0)
		UPDATE [dbo].[tblNotificationSubscription] SET Active = 0 WHERE UserName = @UserName AND SubscriptionKey = @SubscriptionKey
	SELECT @Result
END
GO

PRINT N'Creating [dbo].[netNotificationSubscriptionFindSubscribers]...';
GO

CREATE PROCEDURE [dbo].[netNotificationSubscriptionFindSubscribers]
	@SubscriptionKey [nvarchar](255),
	@Recursive BIT = 1
AS
BEGIN 
	DECLARE @key [nvarchar](256) = @SubscriptionKey + CASE @Recursive WHEN 1 THEN '%' ELSE '' END
	SELECT [pkID], [UserName], [SubscriptionKey] FROM [dbo].[tblNotificationSubscription] WHERE Active = 1 AND SubscriptionKey LIKE @key
END 
GO

PRINT N'Creating [dbo].[netNotificationSubscriptionListSubscriptions]...';
GO

CREATE PROCEDURE [dbo].[netNotificationSubscriptionListSubscriptions]
	@UserName [nvarchar](50)
AS
BEGIN 
	SELECT [pkID], [UserName], [SubscriptionKey] FROM [dbo].[tblNotificationSubscription] WHERE Active = 1 AND UserName = @UserName
END 
GO

PRINT N'Creating [dbo].[netNotificationSubscriptionClearUser]...';
GO

CREATE PROCEDURE [dbo].[netNotificationSubscriptionClearUser]
	@UserName [nvarchar](50)
AS
BEGIN
	DELETE FROM [dbo].[tblNotificationSubscription] WHERE UserName = @UserName
END
GO

PRINT N'Creating [dbo].[netNotificationSubscriptionClearSubscription]...';
GO

CREATE PROCEDURE [dbo].[netNotificationSubscriptionClearSubscription]
	@SubscriptionKey [nvarchar](255)
AS
BEGIN
	DELETE FROM [dbo].[tblNotificationSubscription] WHERE SubscriptionKey LIKE @SubscriptionKey + '%'
END
GO

PRINT N'Altering [dbo].[tblNotificationMessage].[Sender]...';
GO

ALTER TABLE [dbo].[tblNotificationMessage] ALTER COLUMN [Sender] NVARCHAR(255) NULL
GO

PRINT N'Altering [dbo].[tblNotificationMessage].[Recipient]...';
GO

ALTER TABLE [dbo].[tblNotificationMessage] ALTER COLUMN [Recipient] NVARCHAR(255) NULL
GO

PRINT N'Altering [dbo].[tblNotificationSubscription].[UserName]...';
GO

ALTER TABLE [dbo].[tblNotificationSubscription] ALTER COLUMN [UserName] [nvarchar](255) NOT NULL
GO

PRINT N'Update complete.';

GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7027

GO
PRINT N'Update complete.';
GO
--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7029)
				select 0, 'Already correct database version'
            else if (@ver = 7028)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO

PRINT N'Altering [dbo].[netNotificationSubscriptionFindSubscribers]...';
GO

ALTER PROCEDURE [dbo].[netNotificationSubscriptionFindSubscribers]
	@SubscriptionKey [nvarchar](255),
	@Recursive BIT = 1
AS
BEGIN 
	IF (@Recursive = 1)	BEGIN
		DECLARE @key [nvarchar](257) = @SubscriptionKey + CASE SUBSTRING(@SubscriptionKey, LEN(@SubscriptionKey), 1) WHEN N'/' THEN N'%' ELSE N'/%' END
		SELECT [pkID], [UserName], [SubscriptionKey] FROM [dbo].[tblNotificationSubscription] WHERE Active = 1 AND (SubscriptionKey = @SubscriptionKey OR SubscriptionKey LIKE @key)
	END	ELSE BEGIN
		SELECT [pkID], [UserName], [SubscriptionKey] FROM [dbo].[tblNotificationSubscription] WHERE Active = 1 AND SubscriptionKey = @SubscriptionKey
	END
END 
GO

PRINT N'Update complete.';

GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7029

GO
PRINT N'Update complete.';
GO

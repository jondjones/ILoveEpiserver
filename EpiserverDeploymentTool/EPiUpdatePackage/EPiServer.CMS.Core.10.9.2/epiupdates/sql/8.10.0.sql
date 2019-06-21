--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7021)
				select 0, 'Already correct database version'
            else if (@ver = 7020)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery


PRINT N'Rename [dbo].[tblWindowsUser] to tblSynchedUser';

GO
EXECUTE sp_rename @objname = N'[dbo].[tblWindowsUser]', @newname = N'tblSynchedUser', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 76782dd7-8d51-4cc1-ac02-5970d9c8d8b3, d96309b3-ce5d-4881-9adb-d090bb164a68';

PRINT N'Rename [dbo].[tblWindowsGroup] to tblSynchedUserRole';


GO
EXECUTE sp_rename @objname = N'[dbo].[tblWindowsGroup]', @newname = N'tblSynchedUserRole', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 0303dc98-f2a8-478e-ae88-e8c59f335205';

PRINT N'Rename [dbo].[tblWindowsRelations] to tblSynchedUserRelations';


GO
EXECUTE sp_rename @objname = N'[dbo].[tblWindowsRelations]', @newname = N'tblSynchedUserRelations', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 2c76890b-78a1-4767-a540-85006ccb6443';

PRINT N'Rename [dbo].[netWinMembershipGroupDelete] to netSynchedUserGroupDelete';


GO
EXECUTE sp_rename @objname = N'[dbo].[netWinMembershipGroupDelete]', @newname = N'netSynchedUserGroupDelete', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file c777dd75-d879-4e9b-adfd-f0084fa74fca';

PRINT N'Rename [dbo].[netWinMembershipGroupInsert] to netSynchedUserGroupInsert';


GO
EXECUTE sp_rename @objname = N'[dbo].[netWinMembershipGroupInsert]', @newname = N'netSynchedUserGroupInsert', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file eae22f87-1870-4f6a-ba5f-8916ea490e1b, 8e64b59e-64db-4e86-836d-a31be5ed9511, 984d2303-dec7-46be-80b6-90055c367d4a';

PRINT N'Rename [dbo].[netWinMembershipGroupList] to netSynchedUserRoleList';


GO
EXECUTE sp_rename @objname = N'[dbo].[netWinMembershipGroupList]', @newname = N'netSynchedUserRoleList', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 2f9003fd-ca21-4676-8d24-e7e734ffb5b5';

PRINT N'Rename [dbo].[netWinMembershipListUsers] to netSynchedUserList';


GO
EXECUTE sp_rename @objname = N'[dbo].[netWinMembershipListUsers]', @newname = N'netSynchedUserList', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 051ecdd0-894c-43b5-ac6e-be68be82523b';

PRINT N'Rename [dbo].[netWinRoleEnableDisable] to netSynchedUserRoleEnableDisable';


GO
EXECUTE sp_rename @objname = N'[dbo].[netWinRoleEnableDisable]', @newname = N'netSynchedUserRoleEnableDisable', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 1388e061-4dea-4744-adab-268c82d70ac2, a2650c73-8106-48c1-b5e1-cd0c35bd6fe5';

PRINT N'Rename [dbo].[netWinRolesGroupInsert] to netSynchedRoleInsert';


GO
EXECUTE sp_rename @objname = N'[dbo].[netWinRolesGroupInsert]', @newname = N'netSynchedRoleInsert', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 1138744d-0552-4c1d-a808-bab45adcfb15, 05a5bf12-9b16-4065-9021-9e959fe82c23';

PRINT N'Rename [dbo].[netWinRolesList] to netSynchedRolesList';


GO
EXECUTE sp_rename @objname = N'[dbo].[netWinRolesList]', @newname = N'netSynchedRolesList', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 73de51ea-f0ce-432a-8052-a6e189ed09f5';

PRINT N'Rename [dbo].[netWinRolesListStatuses] to netSynchedUserRolesListStatuses';


GO
EXECUTE sp_rename @objname = N'[dbo].[netWinRolesListStatuses]', @newname = N'netSynchedUserRolesListStatuses', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file f5b662a5-69eb-4320-9375-5984516768a6';

PRINT N'Rename [dbo].[netWinRolesUserList] to netSynchedUserMatchRoleList';


GO
EXECUTE sp_rename @objname = N'[dbo].[netWinRolesUserList]', @newname = N'netSynchedUserMatchRoleList', @objtype = N'OBJECT';



GO
PRINT N'The following operation was generated from a refactoring log file 11a6cf2a-c555-4167-9a88-3eee9d50c213';

PRINT N'Rename [dbo].[tblSynchedUserRole].[GroupName] to RoleName';


GO
EXECUTE sp_rename @objname = N'[dbo].[tblSynchedUserRole].[GroupName]', @newname = N'RoleName', @objtype = N'COLUMN';


GO
PRINT N'The following operation was generated from a refactoring log file 16fadb1c-9bfb-4312-9fde-be23599a2a12';

PRINT N'Rename [dbo].[tblSynchedUserRole].[LoweredGroupName] to LoweredRoleName';


GO
EXECUTE sp_rename @objname = N'[dbo].[tblSynchedUserRole].[LoweredGroupName]', @newname = N'LoweredRoleName', @objtype = N'COLUMN';


GO
PRINT N'The following operation was generated from a refactoring log file 9e43af74-e830-445c-a1d1-7098955afaad';

PRINT N'Rename [dbo].[tblSynchedUserRelations].[fkWindowsUser] to fkSynchedUser';


GO
EXECUTE sp_rename @objname = N'[dbo].[tblSynchedUserRelations].[fkWindowsUser]', @newname = N'fkSynchedUser', @objtype = N'COLUMN';


GO
PRINT N'The following operation was generated from a refactoring log file c3ee2572-81ea-421f-b1f8-e30647fb8178';

PRINT N'Rename [dbo].[tblSynchedUserRelations].[fkWindowsGroup] to fkSynchedRole';


GO
EXECUTE sp_rename @objname = N'[dbo].[tblSynchedUserRelations].[fkWindowsGroup]', @newname = N'fkSynchedRole', @objtype = N'COLUMN';


GO
PRINT N'The following operation was generated from a refactoring log file 2204ebf9-e44a-4f10-bc9a-90c8fca52027';

PRINT N'Rename [dbo].[PK_tblWindowsRelations] to PK_tblSynchedUserRelations';


GO
EXECUTE sp_rename @objname = N'[dbo].[PK_tblWindowsRelations]', @newname = N'PK_tblSynchedUserRelations', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 2e53e8b2-2b61-4418-914c-1a266066b3a7';

PRINT N'Rename [dbo].[FK_tblWindowsRelations_Group] to FK_tblSynchedUserRelations_Group';


GO
EXECUTE sp_rename @objname = N'[dbo].[FK_tblWindowsRelations_Group]', @newname = N'FK_tblSynchedUserRelations_Group', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file d325cec6-8403-4297-b6b6-8e4a76d731a4';

PRINT N'Rename [dbo].[FK_tblWindowsRelations_User] to FK_tblSyncheduserRelations_User';


GO
EXECUTE sp_rename @objname = N'[dbo].[FK_tblWindowsRelations_User]', @newname = N'FK_tblSyncheduserRelations_User', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 04b2f2b0-8e54-4e52-abde-6b733ff1f4c5';

PRINT N'Rename [dbo].[PK_tblWindowsGroup] to PK_tblSynchedUserRole';


GO
EXECUTE sp_rename @objname = N'[dbo].[PK_tblWindowsGroup]', @newname = N'PK_tblSynchedUserRole', @objtype = N'OBJECT';


GO
PRINT N'The following operation was generated from a refactoring log file 56cb2e8b-9814-4652-a397-279b05f7d714';

PRINT N'Rename [dbo].[tblSynchedUserRole].[IX_tblWindowsGroup_Unique] to IX_tblSynchedUserRole_Unique';


GO
EXECUTE sp_rename @objname = N'[dbo].[tblSynchedUserRole].[IX_tblWindowsGroup_Unique]', @newname = N'IX_tblSynchedUserRole_Unique', @objtype = N'INDEX';


GO
PRINT N'Rename refactoring operation with key 985d67de-6f8e-4ec8-a232-3153b7a1650d is skipped, element [dbo].[tblNotificationMessage].[Recepient] (SqlSimpleColumn) will not be renamed to Recipient';


GO
PRINT N'Dropping [dbo].[netSynchedUserGroupDelete]...';


GO
DROP PROCEDURE [dbo].[netSynchedUserGroupDelete];


GO
PRINT N'Dropping [dbo].[netSynchedUserGroupInsert]...';


GO
DROP PROCEDURE [dbo].[netSynchedUserGroupInsert];


GO
PRINT N'Dropping [dbo].[netWinRolesGroupDelete]...';


GO
DROP PROCEDURE [dbo].[netWinRolesGroupDelete];


GO
PRINT N'Altering [dbo].[tblSynchedUser]...';


GO
ALTER TABLE [dbo].[tblSynchedUser]
    ADD [Email]            NVARCHAR (255) NULL,
        [GivenName]        NVARCHAR (255) NULL,
        [LoweredGivenName] NVARCHAR (255) NULL,
        [Surname]          NVARCHAR (255) NULL,
        [LoweredSurname]   NVARCHAR (255) NULL,
        [Metadata]         NVARCHAR (MAX) NULL;


GO
PRINT N'Creating [dbo].[tblSynchedUser].[IX_tblWindowsUser_Email]...';


GO
CREATE NONCLUSTERED INDEX [IX_tblWindowsUser_Email]
    ON [dbo].[tblSynchedUser]([Email] ASC);


GO
PRINT N'Creating [dbo].[tblSynchedUser].[IX_tblWindowsUser_LoweredGivenName]...';


GO
CREATE NONCLUSTERED INDEX [IX_tblWindowsUser_LoweredGivenName]
    ON [dbo].[tblSynchedUser]([LoweredGivenName] ASC);


GO
PRINT N'Creating [dbo].[tblSynchedUser].[IX_tblWindowsUser_LoweredSurname]...';


GO
CREATE NONCLUSTERED INDEX [IX_tblWindowsUser_LoweredSurname]
    ON [dbo].[tblSynchedUser]([LoweredSurname] ASC);


GO
PRINT N'Creating [dbo].[tblNotificationMessage]...';


GO
CREATE TABLE [dbo].[tblNotificationMessage] (
    [pkID]      INT            IDENTITY (1, 1) NOT NULL,
    [Sender]    NVARCHAR (50)  NULL,
    [Recipient] NVARCHAR (50)  NOT NULL,
    [Channel]   NVARCHAR (50)  NULL,
    [Type]      NVARCHAR (50)  NULL,
    [Subject]   NVARCHAR (255) NULL,
    [Content]   NVARCHAR (MAX) NULL,
    [Sent]      DATETIME2 (7)  NULL,
    [SendAt]    DATETIME2 (7)  NULL,
    [Saved]     DATETIME2 (7)  NOT NULL,
    [Read]      DATETIME2 (7)  NULL,
    [Category]  NVARCHAR (255) NULL,
    CONSTRAINT [PK_tblNotificationMessage] PRIMARY KEY CLUSTERED ([pkID] ASC)
);


GO
PRINT N'Creating [dbo].[tblNotificationMessage].[IDX_tblNotificationMessage_SendAt]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblNotificationMessage_SendAt]
    ON [dbo].[tblNotificationMessage]([SendAt] ASC);


GO
PRINT N'Creating [dbo].[tblNotificationMessage].[IDX_tblNotificationMessage_Sent]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblNotificationMessage_Sent]
    ON [dbo].[tblNotificationMessage]([Sent] ASC);


GO
PRINT N'Creating [dbo].[tblNotificationMessage].[IDX_tblNotificationMessage_Read]...';


GO
CREATE NONCLUSTERED INDEX [IDX_tblNotificationMessage_Read]
    ON [dbo].[tblNotificationMessage]([Read] ASC);


GO
PRINT N'Altering [dbo].[netSynchedUserRoleList]...';


GO
ALTER PROCEDURE dbo.netSynchedUserRoleList 
(
    @UserID INT = NULL,
	@UserName NVARCHAR(255)
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF (@UserID IS NULL)
	BEGIN
		DECLARE @LoweredName NVARCHAR(255)

		SET @LoweredName=LOWER(@UserName)
		SELECT 
			@UserID=pkID 
		FROM
			[tblSynchedUser]
		WHERE
			LoweredUserName=@LoweredName
	END
	

    /* Get Group name and id */
    SELECT
        [RoleName],
        [fkSynchedRole] AS GroupID
    FROM
        [tblSynchedUserRelations] AS WR
    INNER JOIN
        [tblSynchedUserRole] AS WG
    ON
        WR.[fkSynchedRole]=WG.pkID
    WHERE
        WR.[fkSynchedUser]=@UserID
    ORDER BY
        [RoleName]
END
GO
PRINT N'Altering [dbo].[netSynchedRoleInsert]...';


GO
ALTER PROCEDURE dbo.netSynchedRoleInsert 
(
	@RoleName NVARCHAR(255)
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @LoweredName NVARCHAR(255)

    /* Check if group exists, insert it if not */
	SET @LoweredName=LOWER(@RoleName)
    INSERT INTO [tblSynchedUserRole]
        ([RoleName], 
		[LoweredRoleName])
	SELECT
	    @RoleName,
	    @LoweredName
	WHERE NOT EXISTS(SELECT pkID FROM [tblSynchedUserRole] WHERE [LoweredRoleName]=@LoweredName)
	
    /* Inserted group, return the id */
    IF (@@ROWCOUNT > 0)
    BEGIN
        RETURN  SCOPE_IDENTITY() 
    END
	
	DECLARE @GroupID INT
	SELECT @GroupID=pkID FROM [tblSynchedUserRole] WHERE [LoweredRoleName]=@LoweredName

	RETURN @GroupID
END
GO
PRINT N'Altering [dbo].[netSynchedRolesList]...';


GO
ALTER PROCEDURE dbo.netSynchedRolesList 
(
	@RoleName NVARCHAR(255) = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
    SELECT
        [RoleName]
    FROM
        [tblSynchedUserRole]
    WHERE
		Enabled = 1 AND
        ((@RoleName IS NULL) OR
        ([LoweredRoleName] LIKE LOWER(@RoleName)))
    ORDER BY
        [RoleName]     
END
GO
PRINT N'Altering [dbo].[netSynchedUserRolesListStatuses]...';


GO
ALTER PROCEDURE dbo.netSynchedUserRolesListStatuses 
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
    SELECT
        [RoleName] as Name, Enabled
    FROM
        [tblSynchedUserRole]
    ORDER BY
        [RoleName]     
END
GO
PRINT N'Altering [dbo].[netSynchedUserRoleEnableDisable]...';


GO
ALTER PROCEDURE dbo.netSynchedUserRoleEnableDisable
(
	@RoleName NVARCHAR(255),
	@Enable BIT
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
    UPDATE [tblSynchedUserRole]
        SET Enabled = @Enable
    WHERE
        [LoweredRoleName]=LOWER(@RoleName)
END
GO
PRINT N'Altering [dbo].[netSynchedUserMatchRoleList]...';


GO
ALTER PROCEDURE dbo.netSynchedUserMatchRoleList 
(
	@RoleName NVARCHAR(255),
	@UserNameToMatch NVARCHAR(255) = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @GroupID INT
	SELECT 
	    @GroupID=pkID
	FROM
	    [tblSynchedUserRole]
	WHERE
	    [LoweredRoleName]=LOWER(@RoleName)
	IF (@GroupID IS NULL)
	BEGIN
	    RETURN -1   /* Role does not exist */
	END
	
	SELECT
	    UserName
	FROM
	    [tblSynchedUserRelations] AS WR
	INNER JOIN
	    [tblSynchedUser] AS WU
	ON
	    WU.pkID=WR.[fkSynchedUser]
	WHERE
	    WR.[fkSynchedRole]=@GroupID AND
	    ((WU.LoweredUserName LIKE LOWER(@UserNameToMatch)) OR (@UserNameToMatch IS NULL))
END
GO
PRINT N'Altering [dbo].[netSynchedUserList]...';


GO
ALTER PROCEDURE dbo.netSynchedUserList
(
	@UserNameToMatch NVARCHAR(255) = NULL,
	@StartIndex	INT,
	@MaxCount	INT
)
AS
BEGIN
	SET @UserNameToMatch = LOWER(@UserNameToMatch);

	WITH MatchedSynchedUsersCTE
	AS
	(
		SELECT 
		ROW_NUMBER() OVER (ORDER BY UserName) AS RowNum, UserName, Email, GivenName, Surname
		FROM
		(	
			SELECT
				pkID, UserName, GivenName, Surname, Email
			FROM
				[tblSynchedUser]
			WHERE
				(@UserNameToMatch IS NULL) OR 
				(	([tblSynchedUser].LoweredUserName LIKE @UserNameToMatch + '%') OR 
					([tblSynchedUser].Email LIKE @UserNameToMatch + '%') OR
					([tblSynchedUser].LoweredGivenName LIKE @UserNameToMatch + '%') OR
					([tblSynchedUser].LoweredSurname LIKE @UserNameToMatch + '%')
				)
		)
		AS Result
	)

	SELECT TOP(@MaxCount) UserName, GivenName, Surname, Email, (SELECT COUNT(*) FROM MatchedSynchedUsersCTE) AS 'TotalCount'
		FROM MatchedSynchedUsersCTE 
		WHERE RowNum BETWEEN (@StartIndex - 1) * @MaxCount + 1 AND @StartIndex * @MaxCount 
		ORDER BY UserName
END
GO
PRINT N'Altering [dbo].[netProjectItemGetByReferences]...';


GO
ALTER PROCEDURE [dbo].[netProjectItemGetByReferences]
	@References dbo.ContentReferenceTable READONLY
AS
BEGIN
	SET NOCOUNT ON;
	--ProjectItems
	SELECT
		tblProjectItem.pkID, tblProjectItem.fkProjectID, tblProjectItem.ContentLinkID, tblProjectItem.ContentLinkWorkID, tblProjectItem.ContentLinkProvider, tblProjectItem.Language, tblProjectItem.Category
	FROM
		tblProjectItem
	INNER JOIN @References AS Refs ON Refs.ID = tblProjectItem.ContentLinkID
	WHERE 
		(Refs.WorkID = 0 OR Refs.WorkID = tblProjectItem.ContentLinkWorkID) AND 
		((Refs.Provider IS NULL AND tblProjectItem.ContentLinkProvider = '') OR (Refs.Provider = tblProjectItem.ContentLinkProvider)) 

END
GO

PRINT N'Creating [dbo].[netNotificationMessageList]...';


GO
CREATE PROCEDURE [dbo].[netNotificationMessageList]
	@Recipient NVARCHAR(50) = NULL,
	@Channel NVARCHAR(50) = NULL,
	@Category NVARCHAR(255) = NULL,
	@Read BIT = NULL,
	@Sent BIT = NULL,
	@StartIndex	INT,
	@MaxCount	INT
AS
BEGIN
	WITH MatchedMessagesCTE
	AS
	(
		SELECT 
		ROW_NUMBER() OVER (ORDER BY Recipient) AS RowNum, pkID, Recipient, Sender, Channel, [Type], 
			[Subject], Content, Sent, SendAt, Saved, [Read], Category
		FROM
		(	
			SELECT
				pkID, Recipient, Sender, Channel, [Type], [Subject], Content, Sent, SendAt, Saved, [Read], Category
			FROM
				[tblNotificationMessage]
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

		)
		AS Result
	)

	--take one extra entry to be able to tell caller if last user has more messages
	SELECT TOP(@MaxCount + 1) pkID AS ID, Recipient, Sender, Channel, [Type], [Subject], Content, Sent, SendAt, Saved, 
		[Read], Category, (SELECT COUNT(*) FROM MatchedMessagesCTE) AS 'TotalCount'
		FROM MatchedMessagesCTE 
		WHERE RowNum BETWEEN (@StartIndex - 1) * @MaxCount + 1 AND ((@StartIndex * @MaxCount)) 
		ORDER BY Recipient
END
GO

PRINT N'Creating [dbo].[netNotificationMessageGet]...';

GO
CREATE PROCEDURE [dbo].[netNotificationMessageGet]
	@Id	INT
AS
BEGIN
	SELECT
		pkID AS ID, Recipient, Sender, Channel, [Type], [Subject], Content, Sent, SendAt, Saved, [Read], Category
	FROM
		[tblNotificationMessage]
	WHERE pkID = @Id
END
GO

PRINT N'Creating [dbo].[netNotificationMessageGetForRecipients]...';


GO
CREATE PROCEDURE [dbo].[netNotificationMessageGetForRecipients]
	@ScheduledBefore DATETIME2 = NULL,
	@Recipients dbo.StringParameterTable READONLY
AS
BEGIN
	SELECT
		pkID AS ID, Recipient, Sender, Channel, [Type], [Subject], Content, Sent, SendAt, Saved, [Read], Category
		FROM
			[tblNotificationMessage] AS M INNER JOIN @Recipients AS R ON M.Recipient = R.String
		WHERE
			Sent IS NULL AND
			(SendAt IS NULL OR
			(@ScheduledBefore IS NOT NULL AND SendAt IS NOT NULL AND @ScheduledBefore > SendAt))
					
		ORDER BY Recipient
END
GO
PRINT N'Creating [dbo].[netNotificationMessageGetRecipients]...';


GO
CREATE PROCEDURE [dbo].[netNotificationMessageGetRecipients]
	@Read BIT = NULL,
	@Sent BIT = NULL
AS 
BEGIN
	SELECT DISTINCT(Recipient) FROM tblNotificationMessage
	WHERE 
		(@Read IS NULL OR 
			((@Read = 1 AND [Read] IS NOT NULL) OR
			(@Read = 0 AND [Read] IS NULL)))
		AND
		(@Sent IS NULL OR 
			((@Sent = 1 AND [Sent] IS NOT NULL) OR
			(@Sent = 0 AND [Sent] IS NULL)))
END
GO
PRINT N'Creating [dbo].[netNotificationMessageInsert]...';


GO

CREATE PROCEDURE [dbo].[netNotificationMessageInsert]
	@Recipient NVARCHAR(50),
	@Sender NVARCHAR(50),
	@Channel NVARCHAR(50) = NULL,
	@Type NVARCHAR(50) = NULL,
	@Subject NVARCHAR(255) = NULL,
	@Content NVARCHAR(MAX) = NULL,
	@Saved DATETIME2,
	@SendAt DATETIME2 = NULL,
	@Category NVARCHAR(255) = NULL
AS
BEGIN
	INSERT INTO tblNotificationMessage(Recipient, Sender, Channel, Type, Subject, Content, SendAt, Saved, Category)
	VALUES(@Recipient, @Sender, @Channel, @Type, @Subject, @Content, @SendAt, @Saved, @Category)
	SELECT SCOPE_IDENTITY()
END
GO
PRINT N'Creating [dbo].[netNotificationMessagesDelete]...';


GO
CREATE PROCEDURE [dbo].[netNotificationMessagesDelete]
	@MessageIDs dbo.IDTable READONLY
AS
BEGIN
	DELETE M
	FROM [tblNotificationMessage] AS M INNER JOIN @MessageIDs AS IDS ON M.pkID = IDS.ID
END
GO
PRINT N'Creating [dbo].[netNotificationMessagesRead]...';


GO
CREATE PROCEDURE [dbo].[netNotificationMessagesRead]
	@MessageIDs dbo.IDTable READONLY,
	@Read DATETIME2
AS
BEGIN
	UPDATE M SET [Read] = @Read
	FROM [tblNotificationMessage] AS M INNER JOIN @MessageIDs AS IDS ON M.pkID = IDS.ID
END
GO
PRINT N'Creating [dbo].[netNotificationMessagesSent]...';


GO
CREATE PROCEDURE [dbo].[netNotificationMessagesSent]
	@MessageIDs dbo.IDTable READONLY,
	@Sent DATETIME2
AS
BEGIN
	UPDATE M SET Sent = @Sent
	FROM [tblNotificationMessage] AS M INNER JOIN @MessageIDs AS IDS ON M.pkID = IDS.ID
END
GO
PRINT N'Creating [dbo].[netSynchedRoleDelete]...';


GO
CREATE PROCEDURE dbo.netSynchedRoleDelete
(
	@RoleName NVARCHAR(255),
	@ForceDelete INT
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @GroupID INT
	DECLARE @LoweredName NVARCHAR(255)

    /* Check if group exists */
	SET @LoweredName=LOWER(@RoleName)
	SET @GroupID=NULL
	SELECT
		@GroupID = pkID
	FROM
		[tblSynchedUserRole]
	WHERE
		[LoweredRoleName]=@LoweredName
	
	/* Group does not exist - do nothing */	
    IF (@GroupID IS NULL)
    BEGIN
        RETURN 0
    END
    
    IF (@ForceDelete = 0)
    BEGIN
        IF (EXISTS(SELECT [fkSynchedRole] FROM [tblSynchedUserRelations] WHERE [fkSynchedRole]=@GroupID))
        BEGIN
            RETURN 1    /* Indicate failure - no force delete and group is populated */
        END
    END
    
    DELETE FROM
        [tblSynchedUserRelations]
    WHERE
        [fkSynchedRole]=@GroupID

    DELETE FROM
        [tblSynchedUserRole]
    WHERE
        pkID=@GroupID
        
    RETURN 0
END
GO
PRINT N'Creating [dbo].[netSynchedUserGetMetadata]...';


GO
CREATE PROCEDURE dbo.netSynchedUserGetMetadata
(
	@UserName NVARCHAR(255)
)
AS
BEGIN
	SET @UserName = LOWER(@UserName)
	SELECT Email, GivenName, Surname, Metadata FROM [tblSynchedUser]
	WHERE LoweredUserName = @UserName
END
GO
PRINT N'Creating [dbo].[netSynchedUserInsertOrUpdate]...';


GO

CREATE PROCEDURE dbo.netSynchedUserInsertOrUpdate 
(
	@UserName NVARCHAR(255),
	@GivenName NVARCHAR(255) = NULL,
	@Surname NVARCHAR(255) = NULL,
	@Email NVARCHAR(255) = NULL,
	@Metadata NVARCHAR(MAX) = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @UserID INT
	DECLARE @LoweredName NVARCHAR(255)
	SET @LoweredName=LOWER(@UserName)

	SET @UserID = (SELECT pkID FROM [tblSynchedUser] WHERE LoweredUserName=@LoweredName)
	IF (@UserID IS NOT NULL)
	BEGIN
		UPDATE [tblSynchedUser] SET
			UserName = @UserName,
			LoweredUserName = @LoweredName,
			Email =  LOWER(@Email),
			GivenName = @GivenName,
			LoweredGivenName = LOWER(@GivenName),
			Surname = @Surname,
			LoweredSurname = LOWER(@Surname),
			Metadata = @Metadata
		WHERE 
			pkID = @UserID
	END
	ELSE
	BEGIN
		INSERT INTO [tblSynchedUser] 
			(UserName, LoweredUserName, Email, GivenName, LoweredGivenName, Surname, LoweredSurname, Metadata) 
		SELECT 
			@UserName, 
			@LoweredName,
			Lower(@Email),
			@GivenName,
			Lower(@GivenName),
			@Surname,
			Lower(@Surname),
			@Metadata

		SET @UserID= SCOPE_IDENTITY()
	END

	SELECT @UserID
END
GO
PRINT N'Creating [dbo].[netSynchedUserRoleUpdate]...';


GO

CREATE PROCEDURE dbo.netSynchedUserRoleUpdate
(
	@UserName NVARCHAR(255),
	@Roles dbo.StringParameterTable READONLY
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @UserID INT
	SET @UserID = (SELECT pkID FROM [tblSynchedUser] WHERE LoweredUserName = LOWER(@UserName))
	IF (@UserID IS NULL)
	BEGIN
		RAISERROR(N'No user with username %s was found', 16, 1, @UserName)
	END

	/*First ensure roles are in role table*/
	MERGE [tblSynchedUserRole] AS TARGET
		USING @Roles AS Source
		ON (Target.LoweredRoleName = LOWER(Source.String))
		WHEN NOT MATCHED BY Target THEN
			INSERT (RoleName, LoweredRoleName)
			VALUES (Source.String, LOWER(Source.String));

	/* Remove all existing fole for user */
	DELETE FROM [tblSynchedUserRelations] WHERE [fkSynchedUser] = @UserID

	/* Insert roles */
	INSERT INTO [tblSynchedUserRelations] ([fkSynchedRole], [fkSynchedUser])
	SELECT [tblSynchedUserRole].pkID, @UserID FROM 
	[tblSynchedUserRole] INNER JOIN @Roles AS R ON [tblSynchedUserRole].LoweredRoleName = LOWER(R.String)

END
GO

PRINT N'Creating [dbo].[netNotificationMessagesTruncate]...';
GO

CREATE PROCEDURE [dbo].[netNotificationMessagesTruncate]
(	
	@OlderThan	DATETIME2,
	@MaxRows BIGINT = NULL
)
AS
BEGIN
	IF (@MaxRows IS NOT NULL)
	BEGIN
		DELETE TOP(@MaxRows) FROM [tblNotificationMessage] 
		WHERE Saved < @OlderThan
	END
	ELSE
	BEGIN
		DELETE FROM [tblNotificationMessage] 
		WHERE Saved < @OlderThan
	END

	SELECT @@ROWCOUNT

END
GO


PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7021
GO

PRINT N'Update complete.';


GO

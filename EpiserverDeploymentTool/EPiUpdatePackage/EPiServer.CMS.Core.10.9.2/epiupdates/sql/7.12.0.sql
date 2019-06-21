--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7010)
				select 0, 'Already correct database version'
            else if (@ver = 7009)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO
PRINT N'Altering [dbo].[tblWindowsGroup]...';


GO
ALTER TABLE [dbo].[tblWindowsGroup]
    ADD [Enabled] BIT DEFAULT (1) NOT NULL;


GO
PRINT N'Altering [dbo].[netWinRolesList]...';


GO
ALTER PROCEDURE dbo.netWinRolesList 
(
	@GroupName NVARCHAR(255) = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
    SELECT
        GroupName
    FROM
        tblWindowsGroup
    WHERE
		Enabled = 1 AND
        ((@GroupName IS NULL) OR
        (LoweredGroupName LIKE LOWER(@GroupName)))
    ORDER BY
        GroupName     
END
GO
PRINT N'Creating [dbo].[netWinRoleEnableDisable]...';


GO
CREATE PROCEDURE dbo.netWinRoleEnableDisable
(
	@GroupName NVARCHAR(255),
	@Enable BIT
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
    UPDATE tblWindowsGroup
        SET Enabled = @Enable
    WHERE
        LoweredGroupName=LOWER(@GroupName)
END
GO
PRINT N'Creating [dbo].[netWinRolesListStatuses]...';


GO
CREATE PROCEDURE dbo.netWinRolesListStatuses 
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
    SELECT
        GroupName as Name, Enabled
    FROM
        tblWindowsGroup
    ORDER BY
        GroupName     
END
GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7010
GO
PRINT N'Update complete.';

GO

--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7014)
				select 0, 'Already correct database version'
            else if (@ver = 7013)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO
PRINT N'Altering [dbo].[tblUserPermission]...';

CREATE TABLE [dbo].[tmp_tblUserPermission] 
( 
	[pkID] INT IDENTITY (1, 1) NOT NULL,
    Name NVARCHAR(255), 
    IsRole INT,
	Permission  NVARCHAR(150),
	GroupName	NVARCHAR(150)
)
ALTER TABLE [dbo].[tmp_tblUserPermission] WITH NOCHECK
ADD CONSTRAINT [PK_tmp_tblUserPermission] PRIMARY KEY NONCLUSTERED ([pkID])
CREATE CLUSTERED INDEX [IX_tblUserPermission_Permission_GroupName] ON [dbo].[tmp_tblUserPermission] ([Permission], [GroupName])
GO

INSERT INTO [dbo].[tmp_tblUserPermission] 
SELECT Name,IsRole,
case Permission 
	when 2 then 'DetailedErrorMessage' 
	when 5 then 'WebServiceAccess' 
	when 6 then 'ContentProviderMove' 
end, 'EPiServerCMS'
FROM [dbo].[tblUserPermission]
WHERE Permission=2 OR Permission=5 OR Permission=6
GO
DROP TABLE [dbo].[tblUserPermission]
GO
sp_rename 'dbo.tmp_tblUserPermission', 'tblUserPermission'
GO
sp_rename 'dbo.PK_tmp_tblUserPermission', 'PK_tblUserPermission', N'OBJECT'
GO


ALTER PROCEDURE dbo.netPermissionRoles
(
	@Permission	NVARCHAR(150),
	@GroupName  NVARCHAR(150)
)
AS
BEGIN
    SET NOCOUNT ON
    SELECT
        Name,
        IsRole
    FROM
        tblUserPermission
    WHERE
        Permission=@Permission AND GroupName = @GroupName
    ORDER BY
        IsRole
END
GO

ALTER PROCEDURE dbo.netPermissionSave
(
	@Name NVARCHAR(255) = NULL,
	@IsRole INT = NULL,
	@Permission NVARCHAR(150),
	@GroupName NVARCHAR(150),
	@ClearByName INT = NULL,
	@ClearByPermission INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	
	IF (NOT @ClearByName IS NULL)
		DELETE FROM 
		    tblUserPermission 
		WHERE 
		    Name=@Name AND 
		IsRole=@IsRole
		
	IF (NOT @ClearByPermission IS NULL)
		DELETE FROM 
		    tblUserPermission 
		WHERE 
		    Permission=@Permission AND GroupName = @GroupName	

    IF ((@Name IS NULL) OR (@IsRole IS NULL))
        RETURN
        
	IF (NOT EXISTS(SELECT Name FROM tblUserPermission WHERE Name=@Name AND IsRole=@IsRole AND Permission=@Permission AND GroupName = @GroupName))
		INSERT INTO tblUserPermission 
		    (Name, 
		    IsRole, 
		    Permission,
			GroupName) 
		VALUES 
		    (@Name, 
		    @IsRole, 
		    @Permission,
			@GroupName)
END
GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7014
GO

PRINT N'Update complete.';


GO

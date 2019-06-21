--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7032)
				select 0, 'Already correct database version'
            else if (@ver = 7031)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery
GO

PRINT N'Creating [dbo].[netPlugInLoadByType]...';
GO

CREATE PROCEDURE dbo.netPlugInLoadByType
(
	@AssemblyName NVARCHAR(255),
	@TypeName NVARCHAR(255)
)
AS
BEGIN

	SET NOCOUNT ON
	SELECT pkID, TypeName, AssemblyName, Saved, Created, Enabled FROM tblPlugIn WHERE AssemblyName=@AssemblyName AND TypeName=@TypeName
END
GO

ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7032
GO

PRINT N'Update complete.';
GO

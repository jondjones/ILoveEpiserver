--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7009)
				select 0, 'Already correct database version'
            else if (@ver = 7008)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO
PRINT N'Altering [dbo].[netProjectItemGet]...';


GO
ALTER PROCEDURE [dbo].[netProjectItemGet]
	@ProjectID INT,
	@StartIndex INT = 0,
	@MaxRows INT,
	@Category VARCHAR(2555) = NULL,
	@Language VARCHAR(17) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	WITH PageCTE AS
    (SELECT pkID,fkProjectID, ContentLinkID, ContentLinkWorkID, ContentLinkProvider, Language, Category,
     ROW_NUMBER() OVER(ORDER By pkID) AS intRow
     FROM tblProjectItem
	 WHERE	(@Category IS NULL OR tblProjectItem.Category = @Category) AND 
			(@Language IS NULL OR tblProjectItem.Language = @Language OR tblProjectItem.Language = '') AND
			(tblProjectItem.fkProjectID = @ProjectID))
	 
	--ProjectItems
	SELECT
		  pkID, fkProjectID, ContentLinkID, ContentLinkWorkID, ContentLinkProvider, Language, Category, (SELECT COUNT(*) FROM PageCTE) AS 'TotalRows'
	FROM
		PageCTE
	WHERE intRow BETWEEN (@StartIndex +1) AND (@MaxRows + @StartIndex)
END
GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';


GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7009
GO
PRINT N'Update complete.';


GO

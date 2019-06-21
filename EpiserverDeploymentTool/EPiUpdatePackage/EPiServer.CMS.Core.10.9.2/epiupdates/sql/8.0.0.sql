--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7016)
				select 0, 'Already correct database version'
            else if (@ver = 7015)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO
PRINT N'Altering [dbo].[netCategoryDelete]...';

GO
ALTER PROCEDURE dbo.netCategoryDelete
(
	@CategoryID		INT
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

		/* Find category and descendants */
		;WITH Categories AS (
		  SELECT pkID, 0 as [Level]
		  FROM tblCategory
		  WHERE pkID = @CategoryID
		  UNION ALL
		  SELECT c1.pkID, [Level] + 1
		  FROM tblCategory c1 
			INNER JOIN Categories c2 ON c1.fkParentID = c2.pkID
		 ) 

		/* Reverse order to avoid reference constraint errors */
		SELECT pkID INTO #Reversed FROM Categories ORDER BY [Level] DESC

		/* Delete any references from content tables */
		DELETE FROM tblCategoryPage WHERE fkCategoryID IN (SELECT pkID FROM #Reversed)
		DELETE FROM tblWorkCategory WHERE fkCategoryID IN (SELECT pkID FROM #Reversed)
		
		/* Delete the categories */
		DELETE FROM tblCategory WHERE pkID IN (SELECT pkID FROM #Reversed)

		DROP TABLE #Reversed

	RETURN 0
END

GO
PRINT N'Altering [dbo].[netCategoryListAll]...';

GO
ALTER PROCEDURE dbo.netCategoryListAll
AS
BEGIN
	SET NOCOUNT ON

	;WITH 
	  cte_anchor AS (
		SELECT *,
			   0 AS Indent, 
			   CAST(RIGHT('00000' + CAST(SortOrder as VarChar(6)), 6) AS varchar(MAX)) AS [path]
		   FROM tblCategory
		   WHERE fkParentID IS NULL), 
	  cte_recursive AS (
		 SELECT *
		   FROM cte_anchor
		   UNION ALL
			 SELECT c.*, 
					r.Indent + 1 AS Indent, 
					r.[path] + '.' + CAST(RIGHT('00000' + CAST(c.SortOrder as VarChar(6)), 6) AS varchar(MAX)) AS [path]
			 FROM tblCategory c
			 JOIN cte_recursive r ON c.fkParentID = r.pkID)

	SELECT pkID,
		   fkParentID,
		   CategoryGUID,
		   CategoryName,
		   CategoryDescription,
		   Available,
		   Selectable,
		   SortOrder,
		   Indent
	  FROM cte_recursive 
	  WHERE fkParentID IS NOT NULL
	  ORDER BY [path]


	
	RETURN 0
END

GO
PRINT N'Altering [dbo].[netCategorySave]...';

GO
ALTER PROCEDURE dbo.netCategorySave
(
	@CategoryID		INT OUTPUT,
	@CategoryName	NVARCHAR(50),
	@Description	NVARCHAR(255),
	@Available		BIT,
	@Selectable		BIT,
	@SortOrder		INT,
	@ParentID		INT = NULL,
	@Guid			UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	IF (@CategoryID IS NULL)
	BEGIN
			IF (@SortOrder < 0)
			BEGIN
				SELECT @SortOrder = MAX(SortOrder) + 10 FROM tblCategory 
				IF (@SortOrder IS NULL)
					SET @SortOrder=100
			END
				
			INSERT INTO tblCategory 
				(CategoryName, 
				CategoryDescription, 
				fkParentID, 
				Available, 
				Selectable,
				SortOrder,
				CategoryGUID) 
			VALUES 
				(@CategoryName,
				@Description,
				@ParentID,
				@Available,
				@Selectable,
				@SortOrder,
				COALESCE(@Guid,NewId()))
		SET @CategoryID =  SCOPE_IDENTITY() 
	END
	ELSE
	BEGIN
		UPDATE 
			tblCategory 
		SET 
			CategoryName		= @CategoryName,
			CategoryDescription	= @Description,
			fkParentID			= @ParentID,
			SortOrder			= @SortOrder,
			Available			= @Available,
			Selectable			= @Selectable,
			CategoryGUID		= COALESCE(@Guid,CategoryGUID)
		WHERE 
			pkID=@CategoryID
	END
	
	RETURN 0
END

GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7016
GO

PRINT N'Update complete.';


GO

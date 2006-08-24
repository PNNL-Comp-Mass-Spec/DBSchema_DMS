/****** Object:  View [dbo].[V_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE VIEW dbo.V_Users
AS
SELECT U_PRN, U_Name, ID
FROM T_Users
GO

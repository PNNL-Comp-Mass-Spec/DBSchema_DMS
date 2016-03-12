/****** Object:  View [dbo].[V_Material_Log_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Material_Log_List_Report]
AS
SELECT  TML.ID ,
        TML.Date ,
        TML.Type ,
        TML.Item ,
        TML.Initial_State AS Initial ,
        TML.Final_State AS Final ,
        TU.Name_with_PRN AS [User] ,
        TML.Comment,
        TMC.Comment AS [Container Comment]
FROM    dbo.T_Material_Log TML
        LEFT OUTER JOIN dbo.T_Users TU ON TML.User_PRN = TU.U_PRN
        LEFT OUTER JOIN dbo.T_Material_Containers TMC ON TML.Item = TMC.Tag


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Log_List_Report] TO [PNL\D3M578] AS [dbo]
GO

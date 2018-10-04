/****** Object:  View [dbo].[V_Users_PNNL] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Users_PNNL]
AS
SELECT Src.EMPLID As EmployeeID,
       U.ID As DMS_User_ID,
       Src.HANFORD_ID As HanfordID,
       Src.Business_title As Title,
       Src.PREFERRED_NAME_FM As Person_Name,
       Src.INTERNET_EMAIL_ADDRESS As EMail,
       Src.NETWORK_DOMAIN As Network_Domain,
       Src.NETWORK_ID As Network_ID,
       Src.PNNL_PAY_NO As Payroll_Number,
       IsNull(Src.ACTIVE_SW, 'N') AS Active,
       Src.COMPANY As Company,
       Src.PRIMARY_Bld_No As Building,
       Src.PRIMARY_ROOM_NO As Room,
       Src.PRIMARY_WORK_PHONE As Phone,
       Src.REPORTING_MGR_EMPLID As Mgr_EmployeeID,
       Src.COR_CD As Cost_Code,
       Src.COR_Amount As Cost_Amount
FROM SQLSRVPROD02.opwhse.dbo.VW_PUB_BMI_EMPLOYEE Src
     LEFT OUTER JOIN T_Users U
       ON U.U_HID = 'H' + Src.HANFORD_ID


GO

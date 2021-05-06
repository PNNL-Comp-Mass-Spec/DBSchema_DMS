/****** Object:  View [dbo].[V_EUS_Proposal_User_Lookup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Proposal_User_Lookup]
As
SELECT EU.PERSON_ID AS EUS_User_ID,
       EU.NAME_FM AS EUS_User_Name,
       P.Proposal_ID,
       P.Proposal_Start_Date,
       P.Proposal_End_Date,
       U.U_PRN As User_PRN
FROM T_EUS_Proposal_Users PU
     INNER JOIN T_EUS_Users EU
       ON PU.Person_ID = EU.Person_ID
     INNER JOIN T_EUS_Proposals P
       On PU.Proposal_ID = P.Proposal_ID
     LEFT OUTER JOIN T_Users U
       ON EU.HID = U.U_HID

GO

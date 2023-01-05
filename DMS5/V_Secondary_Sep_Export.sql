/****** Object:  View [dbo].[V_Secondary_Sep_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Secondary_Sep_Export
AS
SELECT SS_ID As Separation_Type_ID, SS_name As Separation_Type, SS_comment As Comment, SS_active As Active, Sep_Group As Separation_Group, SampleType_ID As Sample_Type_ID
FROM T_Secondary_Sep


GO

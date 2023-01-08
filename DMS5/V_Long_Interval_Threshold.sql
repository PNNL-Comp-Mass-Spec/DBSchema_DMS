/****** Object:  View [dbo].[V_Long_Interval_Threshold] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Long_Interval_Threshold
AS
SELECT dbo.GetLongIntervalThreshold() AS threshold_minutes;


GO

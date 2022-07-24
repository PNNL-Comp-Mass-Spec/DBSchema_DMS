/****** Object:  View [dbo].[V_Request_count_by_day] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Request_count_by_day AS
SELECT     CONVERT(datetime, CONVERT(varchar(24), m) + '/' + CONVERT(varchar(24), d) + '/' + CONVERT(varchar(24), y)) AS date, Request, History, Total, 
                      Datasets
FROM         (SELECT     y, m, d, SUM(Request) AS Request, SUM(History) AS History, SUM(Request + History) AS Total, Sum(Datasets) AS Datasets
                       FROM          (SELECT     YEAR(RDS_created) AS y, MONTH(RDS_created) AS m, DAY(RDS_created) AS d, SUM(CASE WHEN DatasetID IS NULL 
                                                                      THEN 1 ELSE 0 END) AS Request, SUM(CASE WHEN DatasetID IS NULL THEN 0 ELSE 1 END) AS History, 0 AS Datasets
                                               FROM          T_Requested_Run
                                               GROUP BY YEAR(RDS_created), MONTH(RDS_created), DAY(RDS_created)
                                               UNION
                                               SELECT     YEAR(DS_created) AS y, MONTH(DS_created) AS m, DAY(DS_created) AS d, 0 AS Request, 0 AS History, COUNT(*) 
                                                                     AS Datasets
                                               FROM         T_Requested_Run INNER JOIN
                                                                     T_Dataset ON T_Requested_Run.DatasetID = T_Dataset.Dataset_ID
                                               GROUP BY YEAR(DS_created), MONTH(DS_created), DAY(DS_created)) M
                       GROUP BY y, m, d) Q

GO
GRANT VIEW DEFINITION ON [dbo].[V_Request_count_by_day] TO [DDL_Viewer] AS [dbo]
GO

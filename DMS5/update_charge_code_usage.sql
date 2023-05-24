/****** Object:  StoredProcedure [dbo].[update_charge_code_usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_charge_code_usage]
/****************************************************
**
**  Desc:   Updates the Usage columns in T_Charge_Code
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   06/04/2013 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/24/2023 mem - Look for work packages that have non-zero usage values but are not actually in use
**
*****************************************************/
(
    @infoOnly tinyint = 0
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    -----------------------------------------------------------
    -- Create the table to hold the data
    -----------------------------------------------------------


    If @infoOnly = 0
    Begin
        --
        -- Look for Charge Codes with a non-zero sample prep usage value, but are no longer associated with a sample prep request
        --
        UPDATE T_Charge_Code
        SET Usage_SamplePrep = 0
        WHERE Usage_SamplePrep > 0 AND
              Charge_Code IN ( SELECT CC.Charge_Code
                               FROM T_Charge_Code CC
                               WHERE Usage_SamplePrep > 0 AND
                                     NOT EXISTS ( SELECT 1
                                                  FROM ( SELECT CC.Charge_Code,
                                                                COUNT(*) AS SPR_Usage
                                                         FROM T_Sample_Prep_Request SPR
                                                              INNER JOIN T_Charge_Code CC
                                                                ON SPR.Work_Package_Number = CC.Charge_Code
                                                         GROUP BY CC.Charge_Code ) StatsQ
                                                  WHERE StatsQ.SPR_Usage > 0 AND
                                                        StatsQ.Charge_Code = CC.Charge_Code ) )

        --
        -- Look for Charge Codes with a non-zero requested run usage value, but are no longer associated with a requested run
        --
        UPDATE T_Charge_Code
        SET Usage_RequestedRun = 0
        WHERE Usage_RequestedRun > 0 AND
              Charge_Code IN ( SELECT CC.Charge_Code
                               FROM T_Charge_Code CC
                               WHERE Usage_RequestedRun > 0 AND
                                     NOT EXISTS ( SELECT 1
                                                  FROM ( SELECT CC.Charge_Code,
                                                                COUNT(*) AS RR_Usage
                                                         FROM T_Charge_Code CC
                                                              INNER JOIN T_Requested_Run RR
                                                                ON CC.Charge_Code = RR.RDS_WorkPackage
                                                         GROUP BY CC.Charge_Code ) StatsQ
                                                  WHERE StatsQ.RR_Usage > 0 AND
                                                        StatsQ.Charge_Code = CC.Charge_Code ) )
        --
        -- Update sample prep request usage stats
        --
        UPDATE T_Charge_Code
        SET Usage_SamplePrep = SPR_Usage
        FROM T_Charge_Code Target
                INNER JOIN ( SELECT CC.Charge_Code,
                                    COUNT(*) AS SPR_Usage
                            FROM T_Sample_Prep_Request SPR
                                INNER JOIN T_Charge_Code CC
                                    ON SPR.Work_Package_Number = CC.Charge_Code
                            GROUP BY CC.Charge_Code
                           ) StatsQ
                ON Target.Charge_Code = StatsQ.Charge_Code
        WHERE IsNull(Target.Usage_SamplePrep, 0) <> SPR_Usage
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        --
        -- Update requested run usage stats
        --
        UPDATE T_Charge_Code
        SET Usage_RequestedRun = RR_Usage
        FROM T_Charge_Code Target
                INNER JOIN ( SELECT CC.Charge_Code,
                                    COUNT(*) AS RR_Usage
                            FROM T_Charge_Code CC
                                INNER JOIN T_Requested_Run RR
                                    ON CC.Charge_Code = RR.RDS_WorkPackage
                            GROUP BY CC.Charge_Code
                           ) StatsQ
                ON Target.Charge_Code = StatsQ.Charge_Code
        WHERE IsNull(Target.Usage_RequestedRun, 0) <> RR_Usage
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End
    Else
    Begin
        --
        -- Show usage stats for all work packages
        --
        SELECT ISNULL(A.Charge_Code, B.Charge_Code) AS Charge_Code,
               A.SPR_Usage,
               B.RR_Usage
        FROM ( SELECT CC.Charge_Code,
                      COUNT(*) AS SPR_Usage
               FROM T_Sample_Prep_Request SPR
                    INNER JOIN T_Charge_Code CC
                      ON SPR.Work_Package_Number = CC.Charge_Code
               GROUP BY CC.Charge_Code
             ) A
             FULL OUTER JOIN ( SELECT CC.Charge_Code,
                                      COUNT(*) AS RR_Usage
                               FROM T_Charge_Code CC
                                    INNER JOIN T_Requested_Run RR
                                      ON CC.Charge_Code = RR.RDS_WorkPackage
                               GROUP BY CC.Charge_Code
             ) B
               ON A.Charge_Code = B.Charge_Code

        --
        -- Look for Charge Codes with a non-zero sample prep usage value, but are no longer associated with a sample prep request
        --
        SELECT CC.Charge_Code,
               CC.Usage_SamplePrep AS Old_Usage,
               0 AS New_Usage,
               CC.WBS_Title,
               CC.Charge_Code_Title,
               CC.SubAccount_Title,
               CC.Setup_Date
        FROM T_Charge_Code CC
        WHERE Usage_SamplePrep > 0 AND
              NOT EXISTS ( SELECT 1
                           FROM ( SELECT CC.Charge_Code,
                                         COUNT(*) AS SPR_Usage
                                  FROM T_Sample_Prep_Request SPR
                                       INNER JOIN T_Charge_Code CC
                                         ON SPR.Work_Package_Number = CC.Charge_Code
                                  GROUP BY CC.Charge_Code ) StatsQ
                           WHERE StatsQ.SPR_Usage > 0 AND
                                 StatsQ.Charge_Code = CC.Charge_Code )
        
        --
        -- Look for Charge Codes with a non-zero requested run usage value, but are no longer associated with a requested run
        --
        SELECT CC.Charge_Code,
               CC.Usage_RequestedRun AS Old_Usage,
               0 AS New_Usage,
               CC.WBS_Title,
               CC.Charge_Code_Title,
               CC.SubAccount_Title,
               CC.Setup_Date
        FROM T_Charge_Code CC
        WHERE Usage_RequestedRun > 0 AND
              NOT EXISTS ( SELECT 1
                           FROM ( SELECT CC.Charge_Code,
                                         COUNT(*) AS RR_Usage
                                  FROM T_Charge_Code CC
                                       INNER JOIN T_Requested_Run RR
                                         ON CC.Charge_Code = RR.RDS_WorkPackage
                                  GROUP BY CC.Charge_Code ) StatsQ
                           WHERE StatsQ.RR_Usage > 0 AND
                                 StatsQ.Charge_Code = CC.Charge_Code )
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_charge_code_usage] TO [DDL_Viewer] AS [dbo]
GO

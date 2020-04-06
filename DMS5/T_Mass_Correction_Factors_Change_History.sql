/****** Object:  Table [dbo].[T_Mass_Correction_Factors_Change_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Mass_Correction_Factors_Change_History](
	[Event_ID] [int] IDENTITY(1,1) NOT NULL,
	[Mass_Correction_ID] [int] NOT NULL,
	[Mass_Correction_Tag] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Monoisotopic_Mass] [float] NOT NULL,
	[Average_Mass] [float] NULL,
	[Affected_Atom] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Original_Source] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Original_Source_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Monoisotopic_Mass_Change] [float] NULL,
	[Average_Mass_Change] [float] NULL,
	[Entered] [datetime] NOT NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Mass_Correction_Factors_Change_History] PRIMARY KEY CLUSTERED 
(
	[Event_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Mass_Correction_Factors_Change_History] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors_Change_History] ADD  CONSTRAINT [DF_T_Mass_Correction_Factors_Change_History_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors_Change_History] ADD  CONSTRAINT [DF_T_Mass_Correction_Factors_Change_History_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO

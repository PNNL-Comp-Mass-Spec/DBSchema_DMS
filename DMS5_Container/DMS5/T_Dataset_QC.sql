/****** Object:  Table [dbo].[T_Dataset_QC] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_QC](
	[Dataset_ID] [int] NOT NULL,
	[SMAQC_Job] [int] NULL,
	[C_1A] [float] NULL,
	[C_1B] [float] NULL,
	[C_2A] [float] NULL,
	[C_2B] [float] NULL,
	[C_3A] [float] NULL,
	[C_3B] [float] NULL,
	[C_4A] [float] NULL,
	[C_4B] [float] NULL,
	[C_4C] [float] NULL,
	[DS_1A] [float] NULL,
	[DS_1B] [float] NULL,
	[DS_2A] [float] NULL,
	[DS_2B] [float] NULL,
	[DS_3A] [float] NULL,
	[DS_3B] [float] NULL,
	[IS_1A] [float] NULL,
	[IS_1B] [float] NULL,
	[IS_2] [float] NULL,
	[IS_3A] [float] NULL,
	[IS_3B] [float] NULL,
	[IS_3C] [float] NULL,
	[MS1_1] [float] NULL,
	[MS1_2A] [float] NULL,
	[MS1_2B] [float] NULL,
	[MS1_3A] [float] NULL,
	[MS1_3B] [float] NULL,
	[MS1_5A] [float] NULL,
	[MS1_5B] [float] NULL,
	[MS1_5C] [float] NULL,
	[MS1_5D] [float] NULL,
	[MS2_1] [float] NULL,
	[MS2_2] [float] NULL,
	[MS2_3] [float] NULL,
	[MS2_4A] [float] NULL,
	[MS2_4B] [float] NULL,
	[MS2_4C] [float] NULL,
	[MS2_4D] [float] NULL,
	[P_1A] [float] NULL,
	[P_1B] [float] NULL,
	[P_2A] [float] NULL,
	[P_2B] [float] NULL,
	[P_2C] [float] NULL,
	[P_3] [float] NULL,
	[Last_Affected] [datetime] NULL,
 CONSTRAINT [PK_T_Dataset_QC] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Dataset_QC]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_QC_T_Dataset] FOREIGN KEY([Dataset_ID])
REFERENCES [T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Dataset_QC] CHECK CONSTRAINT [FK_T_Dataset_QC_T_Dataset]
GO
ALTER TABLE [dbo].[T_Dataset_QC] ADD  CONSTRAINT [DF_T_Dataset_QC_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO

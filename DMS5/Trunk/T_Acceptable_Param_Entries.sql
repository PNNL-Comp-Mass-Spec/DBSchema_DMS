/****** Object:  Table [dbo].[T_Acceptable_Param_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Acceptable_Param_Entries](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Parameter_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Parameter_Category] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Default_Value] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Display_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Canonical_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Analysis_Tool_ID] [int] NOT NULL,
	[First_Applicable_Version] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Applicable_Version] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Param_Entry_Type_ID] [int] NULL,
	[Picker_Items_List] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Output_Order] [int] NULL
) ON [PRIMARY]

GO

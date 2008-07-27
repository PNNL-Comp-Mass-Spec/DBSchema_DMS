/****** Object:  Table [dbo].[T_Filter_Set_Criteria_Groups] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Filter_Set_Criteria_Groups](
	[Filter_Criteria_Group_ID] [int] NOT NULL,
	[Filter_Set_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Filter_Set_Criteria_Groups] PRIMARY KEY CLUSTERED 
(
	[Filter_Criteria_Group_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT INSERT ON [dbo].[T_Filter_Set_Criteria_Groups] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Filter_Set_Criteria_Groups] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Filter_Set_Criteria_Groups] TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Filter_Set_Criteria_Groups]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Filter_Set_Criteria_Groups_T_Filter_Sets] FOREIGN KEY([Filter_Set_ID])
REFERENCES [T_Filter_Sets] ([Filter_Set_ID])
GO
ALTER TABLE [dbo].[T_Filter_Set_Criteria_Groups] CHECK CONSTRAINT [FK_T_Filter_Set_Criteria_Groups_T_Filter_Sets]
GO

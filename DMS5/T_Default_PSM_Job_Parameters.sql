/****** Object:  Table [dbo].[T_Default_PSM_Job_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Default_PSM_Job_Parameters](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Job_Type_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Tool_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DynMetOx] [tinyint] NOT NULL,
	[StatCysAlk] [tinyint] NOT NULL,
	[DynSTYPhos] [tinyint] NOT NULL,
	[Parameter_File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Enabled] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Default_PSM_Job_Parameters] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Default_PSM_Job_Parameters] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Default_PSM_Job_Parameters_Uniq_Type_Tool_MetOx_CysAlk_STYPhos] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Default_PSM_Job_Parameters_Uniq_Type_Tool_MetOx_CysAlk_STYPhos] ON [dbo].[T_Default_PSM_Job_Parameters]
(
	[Job_Type_Name] ASC,
	[Tool_Name] ASC,
	[DynMetOx] ASC,
	[StatCysAlk] ASC,
	[DynSTYPhos] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Parameters] ADD  CONSTRAINT [DF_T_Default_PSM_Job_Parameters_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Parameters]  WITH CHECK ADD  CONSTRAINT [FK_T_Default_PSM_Job_Parameters_T_Analysis_Tool] FOREIGN KEY([Tool_Name])
REFERENCES [dbo].[T_Analysis_Tool] ([AJT_toolName])
GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Parameters] CHECK CONSTRAINT [FK_T_Default_PSM_Job_Parameters_T_Analysis_Tool]
GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Parameters]  WITH CHECK ADD  CONSTRAINT [FK_T_Default_PSM_Job_Parameters_T_Default_PSM_Job_Types] FOREIGN KEY([Job_Type_Name])
REFERENCES [dbo].[T_Default_PSM_Job_Types] ([Job_Type_Name])
GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Parameters] CHECK CONSTRAINT [FK_T_Default_PSM_Job_Parameters_T_Default_PSM_Job_Types]
GO
/****** Object:  Trigger [dbo].[trig_iu_T_Default_PSM_Job_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE Trigger [dbo].[trig_iu_T_Default_PSM_Job_Parameters] on [dbo].[T_Default_PSM_Job_Parameters]
For Insert, Update
/****************************************************
**
**	Desc: 
**		Validates that the parameter file name is valid
**
**	Auth:	mem
**	Date:	11/13/2012 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Declare @ToolName varchar(255)
	Declare @message varchar(512)

	If Update(Tool_Name) OR Update(Parameter_File_Name)
	Begin
		-- Make sure Settings_File_Name is valid
		Declare @ParamFileName varchar(255)
		
		SELECT TOP 1 @ToolName = I.Tool_Name,
		             @ParamFileName = I.Parameter_File_Name
		FROM T_Param_File_Types PFT
		     INNER JOIN T_Param_Files PF
		       ON PFT.Param_File_Type_ID = PF.Param_File_Type_ID
		     INNER JOIN T_Analysis_Tool AnTool
		       ON PFT.Param_File_Type_ID = AnTool.AJT_paramFileType
		     RIGHT OUTER JOIN inserted I
		       ON AnTool.AJT_toolName = I.Tool_Name AND
		          PF.Param_File_Name = I.Parameter_File_Name
		WHERE I.Parameter_File_Name IS NOT NULL AND
		      PF.Param_File_Name IS NULL
		
		If ISNULL(@ParamFileName, '') <> ''
		Begin
			Set @message = 'Parameter file ' + ISNULL(@ParamFileName, '??') + ' is not defined for tool ' + ISNULL(@ToolName, '???') + ' in T_Param_Files (see trigger trig_iu_T_Default_PSM_Job_Parameters)'
			
			RAISERROR(@message,16,1)
	        ROLLBACK TRANSACTION
		    RETURN
		End
	End




GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Parameters] ENABLE TRIGGER [trig_iu_T_Default_PSM_Job_Parameters]
GO

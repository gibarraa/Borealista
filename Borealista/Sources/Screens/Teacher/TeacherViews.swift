import AVFoundation
import SwiftUI

enum TeacherRoute: Hashable {
	case classDetail(UUID)
	case classSettings(UUID)
	case roster(UUID)
	case attendanceScanner(UUID)
}

struct TeacherShellView: View {
	@EnvironmentObject private var appModel: AppModel
	@State private var path: [TeacherRoute] = []
	@State private var showsNewClassComposer = false
	
	private var teacherTabBinding: Binding<TeacherTab> {
		Binding(
			get: { appModel.teacherTab },
			set: { appModel.teacherTab = $0 }
		)
	}
	
	var body: some View {
		NavigationStack(path: $path) {
			ZStack(alignment: .bottom) {
				Group {
					switch appModel.teacherTab {
					case .classes:
						TeacherDashboardView(
							openComposer: { showsNewClassComposer = true },
							navigate: { path.append($0) }
						)
					case .justifications:
						PendingJustificationsView()
					case .profile:
						TeacherProfileView()
					}
				}
				.toolbar(.hidden, for: .navigationBar)
				
				if path.isEmpty {
					TeacherTabBar(selection: teacherTabBinding)
						.padding(.horizontal, 20)
						.padding(.bottom, 12)
						.transition(.move(edge: .bottom).combined(with: .opacity))
				}
			}
			.sheet(isPresented: $showsNewClassComposer) {
				TeacherClassComposerView()
			}
			.navigationDestination(for: TeacherRoute.self) { route in
				switch route {
				case let .classDetail(courseID):
					TeacherClassDetailView(
						courseID: courseID,
						navigate: { path.append($0) }
					)
				case let .classSettings(courseID):
					TeacherClassSettingsView(courseID: courseID)
				case let .roster(courseID):
					TeacherRosterView(courseID: courseID)
				case let .attendanceScanner(courseID):
					TeacherAttendanceScannerView(courseID: courseID)
				}
			}
		}
		.onChange(of: appModel.teacherTab) { _ in
			path.removeAll()
		}
		.task {
			await appModel.ensureTeacherDataLoaded()
			if path.isEmpty, let startupRoute = appModel.consumeStartupTeacherRoute() {
				path = [startupRoute]
			}
		}
	}
}

struct TeacherDashboardView: View {
	@EnvironmentObject private var appModel: AppModel
	let openComposer: () -> Void
	let navigate: (TeacherRoute) -> Void
	
	var body: some View {
		ShellScrollView {
			HStack(spacing: 12) {
				BrandWordmark(logoWidth: 66, fontSize: 31)
				Spacer()
				TeacherMetricPill(
					title: "\(appModel.teacherPendingJustificationCount)",
					icon: "doc.badge.clock",
					tint: BorealistaPalette.cedar,
					isFilled: true
				)
				ProfileAvatar(initials: appModel.currentTeacherProfile.initials, diameter: 52)
			}
			
			ScreenHeader(
				eyebrow: "Docente",
				title: "Mis clases",
				subtitle: nil,
				trailing: AnyView(
					Button(action: openComposer) {
						ZStack {
							Circle()
								.fill(BorealistaPalette.buttonFill)
							Image(systemName: "plus")
								.font(.system(size: 18, weight: .bold))
								.foregroundStyle(.white)
						}
						.frame(width: 46, height: 46)
						.shadow(color: BorealistaPalette.cedar.opacity(0.22), radius: 16, y: 8)
					}
						.buttonStyle(.plain)
				)
			)
			
			PremiumCard(accentOpacity: 0.18, padding: 22) {
				HStack(alignment: .top, spacing: 18) {
					VStack(alignment: .leading, spacing: 12) {
						Text("PANEL DOCENTE")
							.font(BorealistaType.label(11))
							.tracking(3)
							.foregroundStyle(BorealistaPalette.stone)
						
						Text(appModel.currentTeacherProfile.name)
							.font(BorealistaType.display(28))
							.foregroundStyle(BorealistaPalette.wordmarkFill)
						
						Text(appModel.currentTeacherProfile.detail)
							.font(BorealistaType.body(14))
							.foregroundStyle(BorealistaPalette.stone)
						
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 8) {
								TeacherMetricPill(
									title: "\(appModel.teacherCourses.count) activas",
									icon: "rectangle.stack.fill",
									tint: BorealistaPalette.cedar,
									isFilled: true
								)
								TeacherMetricPill(
									title: "\(appModel.teacherStudentCount) alumnos",
									icon: "person.3.fill",
									tint: BorealistaPalette.forest
								)
							}
						}
					}
					
					Spacer(minLength: 0)
					
					BorealistaMark(width: 92)
				}
				
				TeacherMetricStrip(
					metrics: [
						TeacherSummaryMetric(value: "\(appModel.teacherCourses.count)", title: "Clases", icon: "rectangle.stack.fill", tint: BorealistaPalette.cedar),
						TeacherSummaryMetric(value: "\(appModel.teacherStudentCount)", title: "Alumnos", icon: "person.2.fill", tint: BorealistaPalette.forest),
						TeacherSummaryMetric(value: "\(appModel.teacherPendingJustificationCount)", title: "Pendientes", icon: "doc.text.fill", tint: BorealistaPalette.ember)
					]
				)
			}
			
			SectionCaption(
				title: "Activas",
				detail: appModel.teacherCourses.isEmpty ? nil : "\(appModel.teacherStudentCount) alumnos distribuidos en tus grupos"
			)
			
			if appModel.isLoadingTeacherData, appModel.teacherCourses.isEmpty {
				LoadingStateCard(
					title: "Cargando tus clases",
					message: "Sincronizando"
				)
			} else if appModel.teacherCourses.isEmpty {
				EmptyStateCard(
					title: "Aun no hay clases",
					message: "Crea tu primera materia para comenzar a pasar lista."
				)
			} else {
				ForEach(appModel.teacherCourses) { course in
					TeacherManagedCourseCard(course: course) {
						navigate(.classDetail(course.id))
					}
				}
			}
		}
	}
}

struct TeacherClassDetailView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var appModel: AppModel
	
	let courseID: UUID
	let navigate: (TeacherRoute) -> Void
	
	private var course: TeacherManagedCourse? {
		appModel.teacherCourse(id: courseID)
	}
	
	var body: some View {
		ShellScrollView {
			TeacherNavigationBar(
				title: "Clase",
				subtitle: course?.career,
				onBack: { dismiss() }
			)
			
			if let course {
				PremiumCard(accentOpacity: 0.22, padding: 22) {
					HStack(alignment: .top, spacing: 16) {
						VStack(alignment: .leading, spacing: 6) {
							Text(course.name)
								.font(BorealistaType.display(30))
								.foregroundStyle(BorealistaPalette.wordmarkFill)
							
							Text(course.locationSummary)
								.font(BorealistaType.body(14))
								.foregroundStyle(BorealistaPalette.stone)
							
							Text(course.periodSummary)
								.font(BorealistaType.code(12))
								.foregroundStyle(BorealistaPalette.cocoa)
							
							ScrollView(.horizontal, showsIndicators: false) {
								HStack(spacing: 8) {
									TeacherMetricPill(
										title: course.groupName,
										icon: "person.3.fill",
										tint: BorealistaPalette.cedar,
										isFilled: true
									)
									TeacherMetricPill(
										title: "\(course.students.count) alumnos",
										icon: "person.2.fill",
										tint: BorealistaPalette.forest
									)
									TeacherMetricPill(
										title: "\(course.absenceLimit) faltas",
										icon: "exclamationmark.circle.fill",
										tint: BorealistaPalette.ember
									)
								}
							}
						}
						
						Spacer()
						
						BorealistaMark(width: 76)
					}
					
					Divider()
					
					TeacherMetricStrip(
						metrics: [
							TeacherSummaryMetric(value: "\(course.students.count)", title: "Lista", icon: "person.2.fill", tint: BorealistaPalette.forest),
							TeacherSummaryMetric(value: "\(course.scheduleBlocks.count)", title: "Bloques", icon: "clock.fill", tint: BorealistaPalette.cedar),
							TeacherSummaryMetric(value: "\(course.absenceLimit)", title: "Faltas", icon: "exclamationmark.circle.fill", tint: BorealistaPalette.ember)
						]
					)
					
					InfoRow(icon: "building.2.fill", title: "Salon", value: course.classroom)
					InfoRow(icon: "calendar", title: "Periodo", value: course.periodSummary)
				}
				
				PremiumCard(accentOpacity: 0.14) {
					HStack {
						Text("Horario")
							.font(BorealistaType.heading(19))
							.foregroundStyle(BorealistaPalette.ink)
						Spacer()
						TeacherMetricPill(
							title: "\(course.scheduleBlocks.count)",
							icon: "calendar.badge.clock",
							tint: BorealistaPalette.cedar
						)
					}
					
					ForEach(course.scheduleBlocks) { block in
						TeacherScheduleSummaryRow(block: block)
					}
				}
				
				HStack(spacing: 14) {
					TeacherActionTile(
						title: "Alumnos",
						icon: "person.2.fill",
						detail: "\(course.students.count) inscritos",
						action: { navigate(.roster(course.id)) }
					)
					
					TeacherActionTile(
						title: "Ajustes",
						icon: "slider.horizontal.3",
						detail: "Materia y horario",
						action: { navigate(.classSettings(course.id)) }
					)
				}
				
				PrimaryActionButton(title: "Tomar asistencia", systemImage: "qrcode.viewfinder") {
					navigate(.attendanceScanner(course.id))
				}
				
				Text(course.locationSummary)
					.font(BorealistaType.code(12))
					.foregroundStyle(BorealistaPalette.stone)
					.frame(maxWidth: .infinity, alignment: .center)
			} else {
				EmptyStateCard(
					title: "Clase no disponible",
					message: "Esta materia ya no existe dentro de la sesion actual."
				)
			}
		}
		.toolbar(.hidden, for: .navigationBar)
	}
}

struct TeacherClassComposerView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var appModel: AppModel
	
	@State private var draft = TeacherCourseDraft.empty
	@State private var showsScheduleComposer = false
	@State private var alertContext: AlertContext?
	
	var body: some View {
		NavigationStack {
			ShellScrollView {
				TeacherNavigationBar(
					title: "Nueva clase",
					subtitle: "Configura la materia y su horario.",
					onBack: { dismiss() },
					trailingContent: {
						TeacherTrailingCheckButton(action: saveCourse)
					}
				)
				
				TeacherCourseFormContent(
					draft: $draft,
					scheduleAction: { showsScheduleComposer = true }
				)
				.padding(.top, 10)
				
				PrimaryActionButton(title: "Guardar clase", systemImage: "checkmark") {
					saveCourse()
				}
			}
			.toolbar(.hidden, for: .navigationBar)
		}
		.sheet(isPresented: $showsScheduleComposer) {
			TeacherScheduleComposerView(blocks: $draft.scheduleBlocks)
		}
		.alert(item: $alertContext) { context in
			Alert(
				title: Text(context.title),
				message: Text(context.message),
				dismissButton: .default(Text("Entendido"))
			)
		}
	}
	
	private func saveCourse() {
		Task {
			do {
				try await appModel.addTeacherCourse(from: draft)
				dismiss()
			} catch {
				alertContext = AlertContext(
					title: "No se pudo guardar",
					message: error.localizedDescription
				)
			}
		}
	}
}

struct TeacherClassSettingsView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var appModel: AppModel
	
	let courseID: UUID
	
	@State private var draft = TeacherCourseDraft.empty
	@State private var didLoadDraft = false
	@State private var showsScheduleComposer = false
	@State private var showsDeleteConfirmation = false
	@State private var alertContext: AlertContext?
	
	private var course: TeacherManagedCourse? {
		appModel.teacherCourse(id: courseID)
	}
	
	var body: some View {
		ZStack {
			ShellScrollView {
				TeacherNavigationBar(
					title: "Ajustes",
					subtitle: course?.name,
					onBack: { dismiss() },
					trailingContent: {
						TeacherTrailingCheckButton(action: saveChanges)
					}
				)
				
				if course != nil {
					TeacherCourseFormContent(
						draft: $draft,
							scheduleAction: { showsScheduleComposer = true }
					)
					
					Button {
						showsDeleteConfirmation = true
					} label: {
						Text("Eliminar materia")
							.font(BorealistaType.heading(15))
							.foregroundStyle(BorealistaPalette.ember)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 15)
							.background(
								Capsule()
									.fill(Color.white.opacity(0.72))
							)
							.overlay(
								Capsule()
									.stroke(BorealistaPalette.ember.opacity(0.28), lineWidth: 1)
							)
					}
					.buttonStyle(.plain)
				} else {
					EmptyStateCard(
						title: "Clase no disponible",
						message: "No encontramos la clase que querias editar."
					)
				}
			}
			
			if showsDeleteConfirmation {
				TeacherGlassConfirmationModal(
					title: "Eliminar materia",
					message: "Esta accion quitara la clase y su grupo dentro de la sesion actual.",
					confirmTitle: "Eliminar",
					cancelTitle: "Cancelar",
					confirmTint: BorealistaPalette.ember,
					onConfirm: {
						Task {
							do {
								try await appModel.deleteTeacherCourse(id: courseID)
								dismiss()
							} catch {
								alertContext = AlertContext(
									title: "No se pudo eliminar",
									message: error.localizedDescription
								)
							}
						}
					},
					onCancel: {
						showsDeleteConfirmation = false
					}
				)
				.transition(.opacity)
			}
		}
		.toolbar(.hidden, for: .navigationBar)
		.sheet(isPresented: $showsScheduleComposer) {
			TeacherScheduleComposerView(blocks: $draft.scheduleBlocks)
		}
		.alert(item: $alertContext) { context in
			Alert(
				title: Text(context.title),
				message: Text(context.message),
				dismissButton: .default(Text("Entendido"))
			)
		}
		.onAppear {
			guard !didLoadDraft, let course else {
				return
			}
			
			draft = TeacherCourseDraft(course: course)
			didLoadDraft = true
		}
	}
	
	private func saveChanges() {
		Task {
			do {
				try await appModel.updateTeacherCourse(id: courseID, with: draft)
				dismiss()
			} catch {
				alertContext = AlertContext(
					title: "No se pudo guardar",
					message: error.localizedDescription
				)
			}
		}
	}
}

private struct TeacherScheduleComposerView: View {
	@Environment(\.dismiss) private var dismiss
	
	@Binding private var blocks: [ScheduleBlock]
	@State private var workingBlocks: [ScheduleBlock]
	@State private var selectedDays: Set<TeacherWeekday>
	@State private var startTime: String
	@State private var endTime: String
	@State private var editingBlockID: UUID?
	@State private var alertContext: AlertContext?
	
	init(blocks: Binding<[ScheduleBlock]>) {
		_blocks = blocks
		let initialBlocks = blocks.wrappedValue
		_workingBlocks = State(initialValue: initialBlocks)
		_selectedDays = State(initialValue: Set(initialBlocks.first?.days ?? [.monday, .wednesday]))
		_startTime = State(initialValue: initialBlocks.first?.startTime ?? "9:00")
		_endTime = State(initialValue: initialBlocks.first?.endTime ?? "11:00")
	}
	
	var body: some View {
		NavigationStack {
			ShellScrollView {
				TeacherNavigationBar(
					title: "Horario",
					subtitle: "Define los bloques que podras usar al crear la clase.",
					onBack: { dismiss() },
					trailingContent: {
						TeacherTrailingCheckButton(action: confirmSchedule)
					}
				)
				
				PremiumCard(accentOpacity: 0.20, padding: 20) {
					HStack(alignment: .top, spacing: 16) {
						VStack(alignment: .leading, spacing: 10) {
							Text(editingBlockID == nil ? "Nuevo bloque" : "Editando bloque")
								.font(BorealistaType.display(25))
								.foregroundStyle(BorealistaPalette.wordmarkFill)
							
							ScrollView(.horizontal, showsIndicators: false) {
								HStack(spacing: 8) {
									TeacherMetricPill(
										title: "\(workingBlocks.count) guardados",
										icon: "calendar.badge.clock",
										tint: BorealistaPalette.cedar,
										isFilled: true
									)
									TeacherMetricPill(
										title: selectedDays.isEmpty ? "Sin dias" : "\(selectedDays.count) dias",
										icon: "calendar",
										tint: BorealistaPalette.forest
									)
								}
							}
						}
						
						Spacer(minLength: 0)
						
						BorealistaMark(width: 68)
					}
					
					Text("Dias")
						.font(BorealistaType.heading(18))
						.foregroundStyle(BorealistaPalette.ink)
					
					HStack(spacing: 10) {
						ForEach(TeacherWeekday.allCases) { day in
							Button {
								toggleDay(day)
							} label: {
								PillTag(title: day.rawValue, isActive: selectedDays.contains(day))
									.frame(maxWidth: .infinity)
							}
							.buttonStyle(.plain)
						}
					}
					
					HStack(spacing: 12) {
						DateFormField(
							title: "Inicio",
							icon: "clock.fill",
							date: $startTime.asDate(format: "H:mm"),
							components: .hourAndMinute
						)
						
						DateFormField(
							title: "Fin",
							icon: "clock.badge.checkmark.fill",
							date: $endTime.asDate(format: "H:mm"),
							components: .hourAndMinute
						)
					}
					
					PrimaryActionButton(
						title: editingBlockID == nil ? "Agregar bloque de horario" : "Actualizar bloque",
						systemImage: editingBlockID == nil ? "plus" : "checkmark"
					) {
						upsertBlock()
					}
				}
				
				if workingBlocks.isEmpty {
					EmptyStateCard(
						title: "Sin bloques todavia",
						message: "Agrega al menos un horario para poder guardar la materia."
					)
				} else {
					ForEach(workingBlocks) { block in
						PremiumCard {
							HStack(alignment: .top) {
								VStack(alignment: .leading, spacing: 6) {
									Text(block.daysLabel)
										.font(BorealistaType.heading(22))
										.foregroundStyle(BorealistaPalette.ink)
									
									Text(block.compactDays)
										.font(BorealistaType.code(12))
										.foregroundStyle(BorealistaPalette.cocoa)
									
									HStack(spacing: 24) {
										VStack(alignment: .leading, spacing: 4) {
											Text("Inicio")
												.font(BorealistaType.label(12))
												.foregroundStyle(BorealistaPalette.stone)
											Text(block.startTime)
												.font(BorealistaType.heading(16))
												.foregroundStyle(BorealistaPalette.ink)
										}
										
										VStack(alignment: .leading, spacing: 4) {
											Text("Fin")
												.font(BorealistaType.label(12))
												.foregroundStyle(BorealistaPalette.stone)
											Text(block.endTime)
												.font(BorealistaType.heading(16))
												.foregroundStyle(BorealistaPalette.ink)
										}
									}
								}
								
								Spacer()
								
								VStack(spacing: 10) {
									TeacherGlassCircleAction(
										systemImage: "pencil",
										tint: BorealistaPalette.cedar,
										action: { loadBlock(block) }
									)
									
									TeacherGlassCircleAction(
										systemImage: "trash",
										tint: BorealistaPalette.ember,
										action: { deleteBlock(block.id) }
									)
								}
							}
						}
					}
				}
				
				HStack(spacing: 12) {
					SecondaryActionButton(title: "Cancelar") {
						dismiss()
					}
					
					PrimaryActionButton(title: "Confirmar", systemImage: "checkmark") {
						confirmSchedule()
					}
				}
			}
			.toolbar(.hidden, for: .navigationBar)
		}
		.alert(item: $alertContext) { context in
			Alert(
				title: Text(context.title),
				message: Text(context.message),
				dismissButton: .default(Text("Entendido"))
			)
		}
	}
	
	private func toggleDay(_ day: TeacherWeekday) {
		if selectedDays.contains(day) {
			selectedDays.remove(day)
		} else {
			selectedDays.insert(day)
		}
	}
	
	private func upsertBlock() {
		let normalizedStart = startTime.trimmed
		let normalizedEnd = endTime.trimmed
		
		guard !selectedDays.isEmpty else {
			alertContext = AlertContext(
				title: "Dias incompletos",
				message: "Selecciona al menos un dia para continuar."
			)
			return
		}
		
		guard !normalizedStart.isEmpty, !normalizedEnd.isEmpty else {
			alertContext = AlertContext(
				title: "Horario incompleto",
				message: "Escribe una hora de inicio y una hora de fin."
			)
			return
		}
		
		let block = ScheduleBlock(
			id: editingBlockID ?? UUID(),
			days: TeacherWeekday.allCases.filter(selectedDays.contains),
			startTime: normalizedStart,
			endTime: normalizedEnd
		)
		
		if let editingBlockID,
			 let index = workingBlocks.firstIndex(where: { $0.id == editingBlockID }) {
			workingBlocks[index] = block
		} else {
			workingBlocks.append(block)
		}
		
		resetEditor()
	}
	
	private func loadBlock(_ block: ScheduleBlock) {
		editingBlockID = block.id
		selectedDays = Set(block.days)
		startTime = block.startTime
		endTime = block.endTime
	}
	
	private func deleteBlock(_ blockID: UUID) {
		workingBlocks.removeAll { $0.id == blockID }
		
		if editingBlockID == blockID {
			resetEditor()
		}
	}
	
	private func confirmSchedule() {
		guard !workingBlocks.isEmpty else {
			alertContext = AlertContext(
				title: "Horario vacio",
				message: "Agrega al menos un bloque antes de confirmar."
			)
			return
		}
		
		blocks = workingBlocks
		dismiss()
	}
	
	private func resetEditor() {
		editingBlockID = nil
		selectedDays = [.monday, .wednesday]
		startTime = "9:00"
		endTime = "11:00"
	}
}

struct TeacherRosterView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var appModel: AppModel
	
	let courseID: UUID
	
	@State private var query = ""
	@State private var showsAddStudentBar = false
	@State private var pendingStudentCode = ""
	@State private var pendingStudentDeletion: StudentRecord?
	@State private var alertContext: AlertContext?
	
	private var course: TeacherManagedCourse? {
		appModel.teacherCourse(id: courseID)
	}
	
	private var filteredStudents: [StudentRecord] {
		guard let course else {
			return []
		}
		
		if query.trimmed.isEmpty {
			return course.students
		}
		
		return course.students.filter {
			$0.name.localizedCaseInsensitiveContains(query) ||
			$0.idCode.localizedCaseInsensitiveContains(query)
		}
	}
	
	var body: some View {
		ZStack(alignment: .bottomTrailing) {
			ShellScrollView {
				TeacherNavigationBar(
					title: "Alumnos",
					subtitle: course?.name,
					onBack: { dismiss() }
				)
				
				if let course {
					PremiumCard(accentOpacity: 0.18, padding: 20) {
						HStack(alignment: .top, spacing: 16) {
							VStack(alignment: .leading, spacing: 10) {
								Text(course.name)
									.font(BorealistaType.display(27))
									.foregroundStyle(BorealistaPalette.wordmarkFill)
								
								Text(course.career)
									.font(BorealistaType.body(14))
									.foregroundStyle(BorealistaPalette.stone)
								
								ScrollView(.horizontal, showsIndicators: false) {
									HStack(spacing: 8) {
										TeacherMetricPill(
											title: course.groupName,
											icon: "person.3.fill",
											tint: BorealistaPalette.cedar,
											isFilled: true
										)
										TeacherMetricPill(
											title: "\(course.students.count) alumnos",
											icon: "person.2.fill",
											tint: BorealistaPalette.forest
										)
										if !query.trimmed.isEmpty {
											TeacherMetricPill(
												title: "\(filteredStudents.count) visibles",
												icon: "magnifyingglass",
												tint: BorealistaPalette.gold
											)
										}
									}
								}
							}
							
							Spacer(minLength: 0)
							
							BorealistaMark(width: 70)
						}
					}
					
					SoftSearchBar(text: $query, prompt: "Buscar alumno o matricula")
					
					SectionCaption(
						title: query.trimmed.isEmpty ? "Lista" : "Resultados",
						detail: query.trimmed.isEmpty ? nil : "\(filteredStudents.count) coincidencias"
					)
					
					if filteredStudents.isEmpty {
						EmptyStateCard(
							title: "Sin resultados",
							message: query.trimmed.isEmpty ? "Todavia no hay alumnos en este grupo." : "No encontramos coincidencias para tu busqueda."
						)
					} else {
						ForEach(filteredStudents) { student in
							TeacherStudentRow(
								student: student,
								trailingContent: {
									TeacherGlassCircleAction(
										systemImage: "trash",
										tint: BorealistaPalette.ember,
										size: 38
									) {
										pendingStudentDeletion = student
									}
								}
							)
						}
					}
				} else {
					EmptyStateCard(
						title: "Grupo no disponible",
						message: "No encontramos la clase de la que querias ver alumnos."
					)
				}
			}
			
			VStack(alignment: .trailing, spacing: 12) {
				if showsAddStudentBar {
					TeacherInlineEntryBar(
						title: "Ingresa matricula",
						text: $pendingStudentCode,
						keyboardType: .numberPad,
						onConfirm: addStudent
					)
					.transition(.move(edge: .trailing).combined(with: .opacity))
				}
				
				Button {
					withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
						showsAddStudentBar.toggle()
					}
				} label: {
					ZStack {
						Circle()
							.fill(BorealistaPalette.buttonFill)
						Image(systemName: showsAddStudentBar ? "xmark" : "plus")
							.font(.system(size: 20, weight: .bold))
							.foregroundStyle(.white)
					}
					.frame(width: 58, height: 58)
					.shadow(color: BorealistaPalette.cedar.opacity(0.24), radius: 18, y: 10)
				}
				.buttonStyle(.plain)
			}
			.padding(.horizontal, 22)
			.padding(.bottom, 34)
			
			if let pendingStudentDeletion {
				TeacherGlassConfirmationModal(
					title: "Eliminar alumno",
					message: "Se quitara a \(pendingStudentDeletion.name) del grupo actual.",
					confirmTitle: "Eliminar",
					cancelTitle: "Cancelar",
					confirmTint: BorealistaPalette.ember,
					onConfirm: {
						Task {
							do {
								try await appModel.removeStudent(pendingStudentDeletion.id, from: courseID)
								self.pendingStudentDeletion = nil
							} catch {
								alertContext = AlertContext(
									title: "No se pudo eliminar",
									message: error.localizedDescription
								)
							}
						}
					},
					onCancel: {
						self.pendingStudentDeletion = nil
					}
				)
				.transition(.opacity)
			}
		}
		.toolbar(.hidden, for: .navigationBar)
		.alert(item: $alertContext) { context in
			Alert(
				title: Text(context.title),
				message: Text(context.message),
				dismissButton: .default(Text("Entendido"))
			)
		}
	}
	
	private func addStudent() {
		Task {
			do {
				try await appModel.addStudent(studentCode: pendingStudentCode, to: courseID)
				pendingStudentCode = ""
				withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
					showsAddStudentBar = false
				}
			} catch {
				alertContext = AlertContext(
					title: "No se pudo agregar",
					message: error.localizedDescription
				)
			}
		}
	}
}

struct PendingJustificationsView: View {
	@EnvironmentObject private var appModel: AppModel
	@State private var alertContext: AlertContext?
	
	var body: some View {
		ShellScrollView {
			HStack(spacing: 12) {
				BrandWordmark(logoWidth: 62, fontSize: 29)
				Spacer()
				TeacherMetricPill(
					title: "\(appModel.teacherPendingJustificationCount)",
					icon: "doc.badge.clock",
					tint: BorealistaPalette.cedar,
					isFilled: true
				)
			}
			
			ScreenHeader(
				eyebrow: "Revision",
				title: "Justificantes",
				subtitle: nil
			)
			
			PremiumCard(accentOpacity: 0.18, padding: 22) {
				HStack(alignment: .top, spacing: 16) {
					VStack(alignment: .leading, spacing: 10) {
						Text("Solicitudes")
							.font(BorealistaType.display(28))
							.foregroundStyle(BorealistaPalette.wordmarkFill)
						
						Text("\(appModel.teacherPendingJustificationCount) por revisar")
							.font(BorealistaType.body(14))
							.foregroundStyle(BorealistaPalette.stone)
						
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 8) {
								TeacherMetricPill(
									title: "Pendientes",
									icon: "hourglass",
									tint: BorealistaPalette.cedar,
									isFilled: true
								)
								TeacherMetricPill(
									title: appModel.teacherPendingJustificationCount == 0 ? "Todo al dia" : "En revision",
									icon: appModel.teacherPendingJustificationCount == 0 ? "checkmark.seal.fill" : "doc.text.magnifyingglass",
									tint: appModel.teacherPendingJustificationCount == 0 ? BorealistaPalette.forest : BorealistaPalette.gold
								)
							}
						}
					}
					
					Spacer(minLength: 0)
					
					BorealistaMark(width: 78)
				}
			}
			
			if appModel.teacherJustifications.isEmpty {
				EmptyStateCard(
					title: "Sin pendientes",
					message: "No hay justificantes por revisar en este momento."
				)
			} else {
				ForEach(appModel.teacherJustifications) { record in
					TeacherJustificationRow(
						record: record,
						onReject: {
							Task {
								do {
									try await appModel.rejectJustification(record.id)
								} catch {
									alertContext = AlertContext(
										title: "No se pudo rechazar",
										message: error.localizedDescription
									)
								}
							}
						},
						onApprove: {
							Task {
								do {
									try await appModel.approveJustification(record.id)
								} catch {
									alertContext = AlertContext(
										title: "No se pudo aprobar",
										message: error.localizedDescription
									)
								}
							}
						}
					)
				}
			}
		}
		.alert(item: $alertContext) { context in
			Alert(
				title: Text(context.title),
				message: Text(context.message),
				dismissButton: .default(Text("Entendido"))
			)
		}
	}
}

struct TeacherProfileView: View {
	@EnvironmentObject private var appModel: AppModel
	
	@State private var currentPassword = ""
	@State private var newPassword = ""
	@State private var confirmationPassword = ""
	@State private var alertContext: AlertContext?
	
	private var profile: UserProfile {
		appModel.currentTeacherProfile
	}
	
	var body: some View {
		ShellScrollView {
			HStack(spacing: 12) {
				BrandWordmark(logoWidth: 62, fontSize: 29)
				Spacer()
				IconChromeButton(systemImage: "rectangle.portrait.and.arrow.right") {
					withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
						appModel.signOut()
					}
				}
			}
			
			ScreenHeader(
				eyebrow: "Cuenta",
				title: "Perfil",
				subtitle: nil
			)
			
			PremiumCard(accentOpacity: 0.20, padding: 22) {
				HStack(spacing: 18) {
					VStack(alignment: .leading, spacing: 8) {
						Text(profile.name)
							.font(BorealistaType.display(28))
							.foregroundStyle(BorealistaPalette.wordmarkFill)
						Text(profile.role)
							.font(BorealistaType.heading(15))
							.foregroundStyle(BorealistaPalette.cedar)
						Text(profile.detail)
							.font(BorealistaType.body(14))
							.foregroundStyle(BorealistaPalette.stone)
						
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 8) {
								TeacherMetricPill(
									title: "\(appModel.teacherCourses.count) clases",
									icon: "rectangle.stack.fill",
									tint: BorealistaPalette.cedar,
									isFilled: true
								)
								TeacherMetricPill(
									title: "\(appModel.teacherStudentCount) alumnos",
									icon: "person.3.fill",
									tint: BorealistaPalette.forest
								)
							}
						}
					}
					
					Spacer()
					
					VStack(alignment: .trailing, spacing: 12) {
						ProfileAvatar(initials: profile.initials, diameter: 88)
						BorealistaMark(width: 56)
					}
				}
				
				Divider()
				
				ProfileDetailRow(title: "Correo institucional", value: profile.email)
				ProfileDetailRow(title: "Clave docente", value: profile.id)
			}
			
			TeacherMetricStrip(
				metrics: [
					TeacherSummaryMetric(value: "\(appModel.teacherCourses.count)", title: "Clases", icon: "rectangle.stack.fill", tint: BorealistaPalette.cedar),
					TeacherSummaryMetric(value: "\(appModel.teacherStudentCount)", title: "Alumnos", icon: "person.2.fill", tint: BorealistaPalette.forest),
					TeacherSummaryMetric(value: "\(appModel.teacherPendingJustificationCount)", title: "Pendientes", icon: "doc.text.fill", tint: BorealistaPalette.ember)
				]
			)
			
			PremiumCard(accentOpacity: 0.12) {
				HStack {
					Text("Seguridad")
						.font(BorealistaType.heading(19))
						.foregroundStyle(BorealistaPalette.ink)
					Spacer()
					TeacherMetricPill(title: "Acceso", icon: "lock.fill", tint: BorealistaPalette.cedar)
				}
				
				FormField(
					title: "Contraseña actual",
					icon: "lock.fill",
					text: $currentPassword,
					prompt: "Escribe tu contraseña",
					secure: true
				)
				
				FormField(
					title: "Nueva contraseña",
					icon: "key.fill",
					text: $newPassword,
					prompt: "Nueva contraseña",
					secure: true
				)
				
				FormField(
					title: "Confirma nueva contraseña",
					icon: "checkmark.shield.fill",
					text: $confirmationPassword,
					prompt: "Repite tu contraseña",
					secure: true
				)
			}
			
			PrimaryActionButton(title: "Confirmar cambio de contraseña", systemImage: "checkmark") {
				updatePassword()
			}
			
			SecondaryActionButton(title: "Cerrar sesion") {
				withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
					appModel.signOut()
				}
			}
		}
		.alert(item: $alertContext) { context in
			Alert(
				title: Text(context.title),
				message: Text(context.message),
				dismissButton: .default(Text("Entendido"))
			)
		}
	}
	
	private func updatePassword() {
		Task {
			do {
				try await appModel.updateTeacherPassword(
					current: currentPassword,
					new: newPassword,
					confirmation: confirmationPassword
				)
				
				currentPassword = ""
				newPassword = ""
				confirmationPassword = ""
				
				alertContext = AlertContext(
					title: "Contraseña actualizada",
					message: "Tu nueva contraseña se guardo correctamente."
				)
			} catch {
				alertContext = AlertContext(
					title: "No se pudo actualizar",
					message: error.localizedDescription
				)
			}
		}
	}
}

struct TeacherAttendanceScannerView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var appModel: AppModel
	
	let courseID: UUID
	
	@State private var cameraStatus: TeacherScannerAvailability = .starting
	@State private var remainingSeconds = 300
	@State private var isSessionActive = false
	@State private var isStartingSession = true
	@State private var remoteSessionID: Int?
	@State private var scannedCodes: Set<String> = []
	@State private var scannedStudents: [StudentRecord] = []
	@State private var processingCodes: Set<String> = []
	@State private var manualCode = ""
	@State private var statusMessage = "Ventana activa por 5 minutos."
	@State private var alertContext: AlertContext?
	
	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	
	private var course: TeacherManagedCourse? {
		appModel.teacherCourse(id: courseID)
	}
	
	private var attendanceProgress: Double {
		guard let course, !course.students.isEmpty else {
			return 0
		}
		
		return min(Double(scannedCodes.count) / Double(course.students.count), 1)
	}
	
	private var isScreenshotPreview: Bool {
		appModel.activeScreenshotMode == .teacherAttendance
	}
	
	var body: some View {
		ShellScrollView {
			TeacherNavigationBar(
				title: "Tomar asistencia",
				subtitle: course?.name,
				onBack: { dismiss() },
				trailingContent: {
					TeacherTimerBadge(
						seconds: remainingSeconds,
						isActive: isSessionActive
					)
				}
			)
			
			if let course {
				PremiumCard(accentOpacity: 0.20, padding: 20) {
					HStack(alignment: .top, spacing: 16) {
						VStack(alignment: .leading, spacing: 10) {
							Text(course.name)
								.font(BorealistaType.display(27))
								.foregroundStyle(BorealistaPalette.wordmarkFill)
							
							Text(course.groupName)
								.font(BorealistaType.body(14))
								.foregroundStyle(BorealistaPalette.stone)
							
							VStack(alignment: .leading, spacing: 8) {
								HStack(spacing: 8) {
									TeacherMetricPill(
										title: "\(course.students.count) lista",
										icon: "person.2.fill",
										tint: BorealistaPalette.forest
									)
									TeacherMetricPill(
										title: "5 min",
										icon: "timer",
										tint: BorealistaPalette.cedar,
										isFilled: true
									)
								}
								
								TeacherMetricPill(
									title: isSessionActive ? "Sesion activa" : "Sesion cerrada",
									icon: isSessionActive ? "dot.radiowaves.left.and.right" : "pause.circle.fill",
									tint: isSessionActive ? BorealistaPalette.gold : BorealistaPalette.stone
								)
							}
						}
						
						Spacer(minLength: 0)
						
						BorealistaMark(width: 72)
					}
					
					TeacherScannerProgressBar(
						progress: attendanceProgress,
						label: "\(scannedCodes.count) / \(course.students.count) presentes"
					)
				}
				
				PremiumCard(accentOpacity: 0.18, padding: 18) {
					ZStack {
						Group {
							if isScreenshotPreview {
								TeacherScannerMockPreview()
							} else {
								QRScannerCameraView(
									isActive: isSessionActive && !isStartingSession,
									status: $cameraStatus,
									onScanned: registerScannedCode
								)
							}
						}
						.frame(height: 320)
						.clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
						.overlay(
							RoundedRectangle(cornerRadius: 28, style: .continuous)
								.stroke(Color.white.opacity(0.82), lineWidth: 1)
						)
						
						TeacherScannerGuideOverlay()
						
						LinearGradient(
							colors: [Color.clear, Color.black.opacity(0.34)],
							startPoint: .top,
							endPoint: .bottom
						)
						.clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous)
						)
						
						VStack {
							Spacer()
							
							VStack(spacing: 8) {
								if isStartingSession {
									ProgressView()
										.tint(.white)
								}
								
								TeacherScannerStateBadge(
									status: cameraStatus,
									isSessionActive: isSessionActive && !isStartingSession
								)
								
								Text(statusMessage)
									.font(BorealistaType.body(13))
									.foregroundStyle(.white.opacity(0.92))
									.multilineTextAlignment(.center)
							}
							.padding(.horizontal, 18)
							.padding(.bottom, 20)
						}
					}
				}
				
				PremiumCard(accentOpacity: 0.12, padding: 18) {
					HStack {
						VStack(alignment: .leading, spacing: 6) {
							Text("Registros del pase")
								.font(BorealistaType.heading(19))
								.foregroundStyle(BorealistaPalette.ink)
							Text("\(scannedCodes.count) de \(course.students.count) alumnos marcados como presentes")
								.font(BorealistaType.body(13))
								.foregroundStyle(BorealistaPalette.stone)
						}
						
						Spacer()
						
						StatusBadge(
							title: isSessionActive ? "Activa" : "Cerrada",
							tint: isSessionActive ? BorealistaPalette.forest : BorealistaPalette.stone
						)
					}
				}
				
				PremiumCard(accentOpacity: 0.10) {
					HStack {
						Text("Registrar manualmente")
							.font(BorealistaType.heading(18))
							.foregroundStyle(BorealistaPalette.ink)
						Spacer()
						TeacherMetricPill(title: "Matricula", icon: "number.square.fill", tint: BorealistaPalette.cedar)
					}
					
					HStack(spacing: 12) {
						HStack(spacing: 12) {
							Image(systemName: "number.square.fill")
								.foregroundStyle(BorealistaPalette.stone)
							TextField("Matricula del alumno", text: $manualCode)
								.keyboardType(.numberPad)
								.textInputAutocapitalization(.never)
								.font(BorealistaType.body(16))
								.foregroundStyle(BorealistaPalette.ink)
						}
						.padding(.horizontal, 16)
						.padding(.vertical, 15)
						.background(
							ZStack {
								RoundedRectangle(cornerRadius: 22, style: .continuous)
									.fill(Color.white.opacity(0.18))
								RoundedRectangle(cornerRadius: 22, style: .continuous)
									.fill(.ultraThinMaterial)
							}
						)
						.overlay(
							RoundedRectangle(cornerRadius: 22, style: .continuous)
								.stroke(Color.white.opacity(0.78), lineWidth: 1)
						)
						
						TeacherGlassCircleAction(
							systemImage: "checkmark",
							tint: .white,
							size: 48,
							usesGradientBackground: true
						) {
							registerScannedCode(manualCode)
						}
						.disabled(!isSessionActive || isStartingSession)
						.opacity(isSessionActive && !isStartingSession ? 1 : 0.55)
					}
				}
				
				if scannedStudents.isEmpty {
					EmptyStateCard(
						title: "Sin escaneos por ahora",
						message: "Cuando captures un QR generado desde la matricula del alumno, aparecera aqui."
					)
				} else {
					SectionCaption(title: "Registrados", detail: nil)
					
					ForEach(scannedStudents) { student in
						TeacherStudentRow(
							student: student,
							statusTitle: "Registrado",
							statusTint: BorealistaPalette.forest,
							trailingContent: { EmptyView() }
						)
					}
				}
				
				PrimaryActionButton(
					title: isSessionActive ? "Finalizar asistencia" : "Cerrar",
					systemImage: isSessionActive ? "stop.fill" : "checkmark"
				) {
					isSessionActive = false
					dismiss()
				}
			} else {
				EmptyStateCard(
					title: "Clase no disponible",
					message: "No encontramos la materia para abrir la camara de asistencia."
				)
			}
		}
		.toolbar(.hidden, for: .navigationBar)
		.onReceive(timer) { _ in
			guard isSessionActive, !isStartingSession else {
				return
			}
			
			if remainingSeconds > 0 {
				remainingSeconds -= 1
			}
			
			if remainingSeconds == 0 {
				isSessionActive = false
				statusMessage = "La ventana de asistencia termino."
			}
		}
		.alert(item: $alertContext) { context in
			Alert(
				title: Text(context.title),
				message: Text(context.message),
				dismissButton: .default(Text("Entendido"))
			)
		}
		.task {
			if isScreenshotPreview {
				preparePreviewAttendanceSession()
			} else {
				await prepareAttendanceSession()
			}
		}
	}
	
	private func registerScannedCode(_ rawCode: String) {
		if isScreenshotPreview {
			return
		}
		
		let normalizedCode = rawCode.trimmed
		
		guard isSessionActive, !isStartingSession else {
			statusMessage = "La ventana de asistencia ya termino."
			return
		}
		
		guard !normalizedCode.isEmpty else {
			return
		}
		
		guard !scannedCodes.contains(normalizedCode) else {
			statusMessage = "La matricula \(normalizedCode) ya fue registrada."
			return
		}
		
		guard !processingCodes.contains(normalizedCode) else {
			return
		}
		
		processingCodes.insert(normalizedCode)
		
		Task { @MainActor in
			defer { processingCodes.remove(normalizedCode) }
			
			do {
				guard let remoteSessionID else {
					throw BorealistaAPIError.invalidInput("La sesion de asistencia todavia no esta lista.")
				}
				
				let student = try await appModel.registerAttendanceScan(
					studentCode: normalizedCode,
					in: courseID,
					sessionID: remoteSessionID
				)
				
				scannedCodes.insert(normalizedCode)
				scannedStudents.removeAll { $0.id == student.id }
				scannedStudents.insert(student, at: 0)
				manualCode = ""
				statusMessage = "\(student.name) registrado correctamente."
			} catch {
				alertContext = AlertContext(
					title: "No se pudo registrar",
					message: error.localizedDescription
				)
			}
		}
	}
	
	private func prepareAttendanceSession() async {
		guard remoteSessionID == nil else {
			return
		}
		
		isStartingSession = true
		statusMessage = "Preparando la ventana de asistencia..."
		
		do {
			let session = try await appModel.startAttendanceSession(for: courseID)
			remoteSessionID = session.sessionID
			remainingSeconds = session.remainingSeconds
			isSessionActive = session.remainingSeconds > 0
			statusMessage = isSessionActive
			? "Ventana activa por 5 minutos."
			: "La ventana de asistencia ya termino."
		} catch {
			isSessionActive = false
			alertContext = AlertContext(
				title: "No se pudo abrir la asistencia",
				message: error.localizedDescription
			)
		}
		
		isStartingSession = false
	}
	
	private func preparePreviewAttendanceSession() {
		guard let course else {
			return
		}
		
		let previewStudents = Array(course.students.prefix(2))
		scannedStudents = previewStudents
		scannedCodes = Set(previewStudents.map(\.idCode))
		cameraStatus = .ready
		remoteSessionID = -1
		remainingSeconds = 243
		isSessionActive = true
		isStartingSession = false
		statusMessage = "Escanea la matricula QR de cada alumno dentro de esta ventana."
	}
}

private struct TeacherNavigationBar<TrailingContent: View>: View {
	let title: String
	let subtitle: String?
	let onBack: () -> Void
	@ViewBuilder var trailingContent: TrailingContent
	
	init(
		title: String,
		subtitle: String? = nil,
		onBack: @escaping () -> Void,
		@ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
	) {
		self.title = title
		self.subtitle = subtitle
		self.onBack = onBack
		self.trailingContent = trailingContent()
	}
	
	var body: some View {
		HStack(alignment: .center, spacing: 14) {
			IconChromeButton(systemImage: "chevron.left", action: onBack)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(BorealistaType.display(30))
					.foregroundStyle(BorealistaPalette.wordmarkFill)
				
				if let subtitle, !subtitle.isEmpty {
					Text(subtitle)
						.font(BorealistaType.body(13))
						.foregroundStyle(BorealistaPalette.stone)
				}
			}
			
			Spacer()
			
			trailingContent
		}
	}
}

private struct TeacherTrailingCheckButton: View {
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			ZStack {
				Circle()
					.fill(BorealistaPalette.buttonFill)
				Image(systemName: "checkmark")
					.font(.system(size: 16, weight: .bold))
					.foregroundStyle(.white)
			}
			.frame(width: 46, height: 46)
			.shadow(color: BorealistaPalette.cedar.opacity(0.22), radius: 16, y: 8)
		}
		.buttonStyle(.plain)
	}
}

private struct TeacherSummaryMetric: Identifiable {
	let value: String
	let title: String
	let icon: String
	let tint: Color
	
	var id: String { "\(title)-\(value)-\(icon)" }
}

private struct TeacherMetricStrip: View {
	let metrics: [TeacherSummaryMetric]
	
	var body: some View {
		HStack(spacing: 12) {
			ForEach(metrics) { metric in
				TeacherHeroMetric(
					value: metric.value,
					title: metric.title,
					icon: metric.icon,
					tint: metric.tint
				)
			}
		}
	}
}

private struct TeacherMetricPill: View {
	let title: String
	let icon: String
	let tint: Color
	var isFilled = false
	
	var body: some View {
		HStack(spacing: 6) {
			Image(systemName: icon)
				.font(.system(size: 11, weight: .semibold))
			Text(title)
				.font(BorealistaType.code(11))
				.lineLimit(1)
				.minimumScaleFactor(0.84)
		}
		.foregroundStyle(isFilled ? Color.white : tint)
		.padding(.horizontal, 11)
		.padding(.vertical, 8)
		.background(
			Capsule()
				.fill(isFilled ? AnyShapeStyle(BorealistaPalette.buttonFill) : AnyShapeStyle(tint.opacity(0.10)))
		)
		.overlay(
			Capsule()
				.stroke(isFilled ? Color.white.opacity(0.16) : tint.opacity(0.16), lineWidth: 0.8)
		)
	}
}

private struct TeacherHeroMetric: View {
	let value: String
	let title: String
	var icon: String = "circle.fill"
	var tint: Color = BorealistaPalette.cedar
	
	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Image(systemName: icon)
				.font(.system(size: 13, weight: .semibold))
				.foregroundStyle(tint)
			Text(value)
				.font(BorealistaType.display(24))
				.foregroundStyle(BorealistaPalette.wordmarkFill)
				.lineLimit(1)
				.minimumScaleFactor(0.80)
			Text(title)
				.font(BorealistaType.body(12))
				.foregroundStyle(BorealistaPalette.stone)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16)
		.background(
			ZStack {
				RoundedRectangle(cornerRadius: 24, style: .continuous)
					.fill(Color.white.opacity(0.16))
				RoundedRectangle(cornerRadius: 24, style: .continuous)
					.fill(.ultraThinMaterial)
				RoundedRectangle(cornerRadius: 24, style: .continuous)
					.fill(
						LinearGradient(
							colors: [Color.white.opacity(0.78), tint.opacity(0.08)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
			}
		)
		.overlay(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.stroke(Color.white.opacity(0.78), lineWidth: 1)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.stroke(BorealistaPalette.line.opacity(0.24), lineWidth: 0.8)
		)
	}
}

private struct TeacherManagedCourseCard: View {
	let course: TeacherManagedCourse
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			PremiumCard(accentOpacity: 0.18, padding: 20) {
				HStack(alignment: .top, spacing: 16) {
					ZStack {
						Circle()
							.fill(BorealistaPalette.courseGradient(course.accent))
							.opacity(0.20)
						Circle()
							.stroke(Color.white.opacity(0.82), lineWidth: 1)
						Text(course.initials)
							.font(BorealistaType.code(15))
							.foregroundStyle(BorealistaPalette.cedar)
					}
					.frame(width: 58, height: 58)
					
					VStack(alignment: .leading, spacing: 8) {
						Text(course.name)
							.font(BorealistaType.heading(21))
							.foregroundStyle(BorealistaPalette.ink)
							.multilineTextAlignment(.leading)
						
						Text(course.career)
							.font(BorealistaType.body(13))
							.foregroundStyle(BorealistaPalette.stone)
						
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 8) {
								TeacherMetricPill(
									title: course.groupName,
									icon: "person.3.fill",
									tint: BorealistaPalette.cedar,
									isFilled: true
								)
								TeacherMetricPill(
									title: "\(course.students.count) alumnos",
									icon: "person.2.fill",
									tint: BorealistaPalette.forest
								)
							}
						}
					}
					
					Spacer(minLength: 12)
					
					Image(systemName: "chevron.right")
						.font(.system(size: 13, weight: .semibold))
						.foregroundStyle(BorealistaPalette.cedar)
				}
				
				HStack(spacing: 10) {
					TeacherMetricPill(
						title: course.scheduleSummary,
						icon: "clock.fill",
						tint: BorealistaPalette.gold
					)
					TeacherMetricPill(
						title: course.classroom,
						icon: "building.2.fill",
						tint: BorealistaPalette.cocoa
					)
				}
			}
		}
		.buttonStyle(.plain)
	}
}

private struct TeacherScheduleSummaryRow: View {
	let block: ScheduleBlock
	
	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: "calendar")
				.font(.system(size: 14, weight: .semibold))
				.foregroundStyle(BorealistaPalette.cedar)
				.frame(width: 16)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(block.daysLabel)
					.font(BorealistaType.heading(16))
					.foregroundStyle(BorealistaPalette.ink)
				Text(block.timeLabel)
					.font(BorealistaType.body(13))
					.foregroundStyle(BorealistaPalette.stone)
			}
			
			Spacer()
			
			Text(block.compactDays)
				.font(BorealistaType.code(11))
				.foregroundStyle(BorealistaPalette.cocoa)
		}
		.padding(16)
		.background(
			ZStack {
				RoundedRectangle(cornerRadius: 22, style: .continuous)
					.fill(Color.white.opacity(0.16))
				RoundedRectangle(cornerRadius: 22, style: .continuous)
					.fill(.ultraThinMaterial)
				RoundedRectangle(cornerRadius: 22, style: .continuous)
					.fill(
						LinearGradient(
							colors: [Color.white.opacity(0.78), BorealistaPalette.blush.opacity(0.08)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
			}
		)
		.overlay(
			RoundedRectangle(cornerRadius: 22, style: .continuous)
				.stroke(Color.white.opacity(0.78), lineWidth: 1)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 22, style: .continuous)
				.stroke(BorealistaPalette.line.opacity(0.22), lineWidth: 0.8)
		)
	}
}

private struct TeacherActionTile: View {
	let title: String
	let icon: String
	var detail: String? = nil
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			PremiumCard(accentOpacity: 0.10, padding: 18) {
				VStack(alignment: .leading, spacing: 14) {
					ZStack {
						Circle()
							.fill(BorealistaPalette.blush.opacity(0.18))
						Image(systemName: icon)
							.font(.system(size: 20, weight: .semibold))
							.foregroundStyle(BorealistaPalette.cedar)
					}
					.frame(width: 46, height: 46)
					
					Text(title)
						.font(BorealistaType.heading(17))
						.foregroundStyle(BorealistaPalette.ink)
					
					if let detail, !detail.isEmpty {
						Text(detail)
							.font(BorealistaType.body(13))
							.foregroundStyle(BorealistaPalette.stone)
					}
				}
			}
		}
		.buttonStyle(.plain)
	}
}

private struct TeacherCourseFormContent: View {
	@Binding var draft: TeacherCourseDraft
	let scheduleAction: () -> Void
	
	var body: some View {
		VStack(spacing: 16) {
			PremiumCard(accentOpacity: 0.18, padding: 20) {
				HStack(alignment: .top, spacing: 16) {
					VStack(alignment: .leading, spacing: 10) {
						Text(previewTitle)
							.font(BorealistaType.display(26))
							.foregroundStyle(BorealistaPalette.wordmarkFill)
						
						Text(previewSubtitle)
							.font(BorealistaType.body(14))
							.foregroundStyle(BorealistaPalette.stone)
						
						if !previewTags.isEmpty {
							ScrollView(.horizontal, showsIndicators: false) {
								HStack(spacing: 8) {
									ForEach(previewTags, id: \.self) { tag in
										PillTag(title: tag, isActive: tag == draft.groupName.trimmed)
									}
								}
							}
						}
					}
					
					Spacer(minLength: 0)
					
					BorealistaMark(width: 72)
				}
			}
			.padding(.top, 12)
			
			PremiumCard {
				HStack {
					Text("Detalle")
						.font(BorealistaType.heading(19))
						.foregroundStyle(BorealistaPalette.ink)
					Spacer()
					TeacherMetricPill(title: "Materia", icon: "square.and.pencil", tint: BorealistaPalette.cedar)
				}
				
				FormField(
					title: "Nombre de materia",
					icon: "book.closed.fill",
					text: $draft.name,
					prompt: "Matematicas avanzadas",
					autocapitalization: .words
				)
				
				FormField(
					title: "Salon",
					icon: "building.2.fill",
					text: $draft.classroom,
					prompt: "Salon 302",
					autocapitalization: .words
				)
				
				FormField(
					title: "Carrera",
					icon: "graduationcap.fill",
					text: $draft.career,
					prompt: "Ingenieria en software",
					autocapitalization: .words
				)
				
				FormField(
					title: "Grupo",
					icon: "person.3.fill",
					text: $draft.groupName,
					prompt: "Grupo 3A",
					autocapitalization: .words
				)
				
				FormField(
					title: "Numero de faltas",
					icon: "exclamationmark.circle.fill",
					text: $draft.absenceLimit,
					prompt: "3",
					keyboardType: .numberPad
				)
				
				HStack(spacing: 12) {
					DateFormField(
						title: "Periodo inicial",
						icon: "calendar",
						date: $draft.periodStart.asDate(format: "d MMM yyyy"),
						components: .date
					)

					DateFormField(
						title: "Periodo final",
						icon: "calendar.badge.clock",
						date: $draft.periodEnd.asDate(format: "d MMM yyyy"),
						components: .date
					)
				}
			}
			
			PremiumCard(accentOpacity: 0.14) {
				HStack {
					Text("Horario")
						.font(BorealistaType.heading(19))
						.foregroundStyle(BorealistaPalette.ink)
					
					Spacer()
					
					Button("Editar") {
						scheduleAction()
					}
					.font(BorealistaType.heading(14))
					.foregroundStyle(BorealistaPalette.cedar)
				}
				
				if draft.scheduleBlocks.isEmpty {
					Text("Agrega al menos un bloque de horario.")
						.font(BorealistaType.body(14))
						.foregroundStyle(BorealistaPalette.stone)
				} else {
					ForEach(draft.scheduleBlocks) { block in
						TeacherScheduleSummaryRow(block: block)
					}
				}
				
				SecondaryActionButton(title: draft.scheduleBlocks.isEmpty ? "Agregar horario" : "Editar horario") {
					scheduleAction()
				}
			}
			.padding(.bottom, 12)
		}
	}
	
	private var previewTitle: String {
		let normalized = draft.name.trimmed
		return normalized.isEmpty ? "Nueva materia" : normalized
	}
	
	private var previewSubtitle: String {
		let descriptors = [
			draft.career.trimmed,
			draft.classroom.trimmed
		].filter { !$0.isEmpty }
		
		return descriptors.isEmpty ? "Borealista" : descriptors.joined(separator: " · ")
	}
	
	private var previewTags: [String] {
		[
			draft.groupName.trimmed,
			draft.periodStart.trimmed,
			draft.periodEnd.trimmed
		].filter { !$0.isEmpty }
	}
}

private struct TeacherStudentRow<TrailingContent: View>: View {
	let student: StudentRecord
	var statusTitle: String?
	var statusTint: Color?
	@ViewBuilder var trailingContent: TrailingContent
	
	init(
		student: StudentRecord,
		statusTitle: String? = nil,
		statusTint: Color? = nil,
		@ViewBuilder trailingContent: () -> TrailingContent
	) {
		self.student = student
		self.statusTitle = statusTitle
		self.statusTint = statusTint
		self.trailingContent = trailingContent()
	}
	
	var body: some View {
		HStack(spacing: 14) {
			ProfileAvatar(initials: studentInitials, diameter: 48)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(student.name)
					.font(BorealistaType.heading(17))
					.foregroundStyle(BorealistaPalette.ink)
				Text(student.idCode)
					.font(BorealistaType.code(12))
					.foregroundStyle(BorealistaPalette.stone)
			}
			
			Spacer()
			
			if let statusTitle, let statusTint {
				StatusBadge(title: statusTitle, tint: statusTint)
			} else {
				StatusBadge(title: student.attendance.rawValue, tint: student.attendance.tint)
			}
			
			trailingContent
		}
		.padding(16)
		.background(
			ZStack {
				RoundedRectangle(cornerRadius: 24, style: .continuous)
					.fill(Color.white.opacity(0.16))
				RoundedRectangle(cornerRadius: 24, style: .continuous)
					.fill(.ultraThinMaterial)
				RoundedRectangle(cornerRadius: 24, style: .continuous)
					.fill(
						LinearGradient(
							colors: [Color.white.opacity(0.80), BorealistaPalette.pearl.opacity(0.66)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
			}
		)
		.overlay(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.stroke(Color.white.opacity(0.78), lineWidth: 1)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.stroke(BorealistaPalette.line.opacity(0.22), lineWidth: 0.8)
		)
		.shadow(color: BorealistaPalette.espresso.opacity(0.06), radius: 16, y: 8)
	}
	
	private var studentInitials: String {
		let parts = student.name.split(separator: " ")
		let letters = parts.prefix(2).compactMap(\.first)
		let value = String(letters).uppercased()
		return value.isEmpty ? "AL" : value
	}
}

private struct TeacherJustificationRow: View {
	let record: JustificationRecord
	let onReject: () -> Void
	let onApprove: () -> Void
	
	var body: some View {
		PremiumCard(accentOpacity: 0.16) {
			VStack(alignment: .leading, spacing: 14) {
				HStack(alignment: .top) {
					HStack(spacing: 14) {
						ProfileAvatar(initials: studentInitials, diameter: 50)
						
						VStack(alignment: .leading, spacing: 4) {
							Text(record.studentName)
								.font(BorealistaType.heading(20))
								.foregroundStyle(BorealistaPalette.ink)
							Text(record.studentCode)
								.font(BorealistaType.code(12))
								.foregroundStyle(BorealistaPalette.cocoa)
						}
					}
					
					Spacer()
					
					StatusBadge(title: "Pendiente", tint: BorealistaPalette.cedar)
				}
				
				Text(record.date)
					.font(BorealistaType.code(12))
					.foregroundStyle(BorealistaPalette.stone)
				
				Text(record.summary)
					.font(BorealistaType.body(14))
					.foregroundStyle(BorealistaPalette.stone)
				
				Text(record.courseTitle)
					.font(BorealistaType.body(13))
					.foregroundStyle(BorealistaPalette.cocoa)
				
				HStack(spacing: 12) {
					Button(action: onReject) {
						Text("Rechazar")
							.font(BorealistaType.heading(14))
							.foregroundStyle(BorealistaPalette.ember)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 14)
							.background(Capsule().fill(Color.white.opacity(0.82)))
							.overlay(
								Capsule()
									.stroke(BorealistaPalette.ember.opacity(0.22), lineWidth: 1)
							)
					}
					.buttonStyle(.plain)
					
					Button(action: onApprove) {
						Text("Aprobar")
							.font(BorealistaType.heading(14))
							.foregroundStyle(.white)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 14)
							.background(Capsule().fill(BorealistaPalette.buttonFill))
					}
					.buttonStyle(.plain)
				}
			}
		}
	}
	
	private var studentInitials: String {
		let parts = record.studentName.split(separator: " ")
		let letters = parts.prefix(2).compactMap(\.first)
		let value = String(letters).uppercased()
		return value.isEmpty ? "AL" : value
	}
}

private struct TeacherInlineEntryBar: View {
	let title: String
	@Binding var text: String
	let keyboardType: UIKeyboardType
	let onConfirm: () -> Void
	
	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: "number.square.fill")
				.foregroundStyle(BorealistaPalette.stone)
			
			TextField(title, text: $text)
				.keyboardType(keyboardType)
				.textInputAutocapitalization(.never)
				.font(BorealistaType.body(15))
				.foregroundStyle(BorealistaPalette.ink)
			
			TeacherGlassCircleAction(
				systemImage: "checkmark",
				tint: .white,
				size: 44,
				usesGradientBackground: true,
				action: onConfirm
			)
		}
		.padding(.horizontal, 18)
		.padding(.vertical, 16)
		.frame(width: min(UIScreen.main.bounds.width - 88, 300))
		.background(
			ZStack {
				RoundedRectangle(cornerRadius: 24, style: .continuous)
					.fill(Color.white.opacity(0.14))
				RoundedRectangle(cornerRadius: 24, style: .continuous)
					.fill(.ultraThinMaterial)
				RoundedRectangle(cornerRadius: 24, style: .continuous)
					.fill(
						LinearGradient(
							colors: [Color.white.opacity(0.86), BorealistaPalette.pearl.opacity(0.74)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
			}
		)
		.overlay(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.stroke(Color.white.opacity(0.82), lineWidth: 1)
		)
		.shadow(color: BorealistaPalette.espresso.opacity(0.12), radius: 20, y: 10)
	}
}

private struct TeacherGlassConfirmationModal: View {
	let title: String
	let message: String
	let confirmTitle: String
	let cancelTitle: String
	let confirmTint: Color
	let onConfirm: () -> Void
	let onCancel: () -> Void
	
	var body: some View {
		ZStack {
			Color.black.opacity(0.18)
				.ignoresSafeArea()
			
			VStack(spacing: 16) {
				BorealistaMark(width: 56)
				
				Text(title)
					.font(BorealistaType.display(24))
					.foregroundStyle(BorealistaPalette.wordmarkFill)
				
				Text(message)
					.font(BorealistaType.body(14))
					.foregroundStyle(BorealistaPalette.stone)
					.multilineTextAlignment(.center)
				
				HStack(spacing: 12) {
					Button(action: onConfirm) {
						Text(confirmTitle)
							.font(BorealistaType.heading(14))
							.foregroundStyle(confirmTint)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 14)
							.background(Capsule().fill(Color.white.opacity(0.82)))
							.overlay(
								Capsule()
									.stroke(confirmTint.opacity(0.20), lineWidth: 1)
							)
					}
					.buttonStyle(.plain)
					
					Button(action: onCancel) {
						Text(cancelTitle)
							.font(BorealistaType.heading(14))
							.foregroundStyle(BorealistaPalette.ink)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 14)
							.background(Capsule().fill(Color.white.opacity(0.82)))
					}
					.buttonStyle(.plain)
				}
			}
			.padding(24)
			.frame(maxWidth: 320)
			.background(
				ZStack {
					RoundedRectangle(cornerRadius: 30, style: .continuous)
						.fill(Color.white.opacity(0.20))
					RoundedRectangle(cornerRadius: 30, style: .continuous)
						.fill(.ultraThinMaterial)
					RoundedRectangle(cornerRadius: 30, style: .continuous)
						.fill(
							LinearGradient(
								colors: [Color.white.opacity(0.88), BorealistaPalette.pearl.opacity(0.80)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
				}
			)
			.overlay(
				RoundedRectangle(cornerRadius: 30, style: .continuous)
					.stroke(Color.white.opacity(0.84), lineWidth: 1)
			)
			.shadow(color: BorealistaPalette.espresso.opacity(0.16), radius: 30, y: 18)
		}
	}
}

private struct TeacherTimerBadge: View {
	let seconds: Int
	let isActive: Bool
	
	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: "timer")
				.font(.system(size: 11, weight: .bold))
			Text(timeLabel)
				.font(BorealistaType.code(12))
		}
		.foregroundStyle(isActive ? BorealistaPalette.cedar : BorealistaPalette.stone)
		.padding(.horizontal, 14)
		.padding(.vertical, 10)
		.background(
			ZStack {
				Capsule()
					.fill(Color.white.opacity(0.18))
				Capsule()
					.fill(.ultraThinMaterial)
				Capsule()
					.fill(
						LinearGradient(
							colors: [Color.white.opacity(0.82), BorealistaPalette.pearl.opacity(0.72)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
			}
		)
		.overlay(
			Capsule()
				.stroke(Color.white.opacity(0.82), lineWidth: 1)
		)
		.overlay(
			Capsule()
				.stroke(BorealistaPalette.line.opacity(0.28), lineWidth: 0.8)
		)
	}
	
	private var timeLabel: String {
		let minutes = max(seconds, 0) / 60
		let remaining = max(seconds, 0) % 60
		return String(format: "%02d:%02d", minutes, remaining)
	}
}

private enum TeacherScannerAvailability: Equatable {
	case starting
	case ready
	case denied
	case unavailable
}

private struct TeacherScannerStateBadge: View {
	let status: TeacherScannerAvailability
	let isSessionActive: Bool
	
	var body: some View {
		Text(title)
			.font(BorealistaType.code(11))
			.foregroundStyle(.white)
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.background(
				ZStack {
					Capsule()
						.fill(Color.black.opacity(0.24))
					Capsule()
						.fill(.ultraThinMaterial.opacity(0.28))
				}
			)
			.overlay(
				Capsule()
					.stroke(Color.white.opacity(0.18), lineWidth: 0.8)
			)
	}
	
	private var title: String {
		guard isSessionActive else {
			return "Ventana cerrada"
		}
		
		switch status {
		case .starting:
			return "Preparando camara"
		case .ready:
			return "Camara lista"
		case .denied:
			return "Permite la camara para escanear"
		case .unavailable:
			return "Usa captura manual"
		}
	}
}

private struct TeacherGlassCircleAction: View {
	let systemImage: String
	let tint: Color
	var size: CGFloat = 36
	var usesGradientBackground = false
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			Image(systemName: systemImage)
				.font(.system(size: size * 0.36, weight: .semibold))
				.foregroundStyle(tint)
				.frame(width: size, height: size)
				.background(
					ZStack {
						Circle()
							.fill(Color.white.opacity(0.18))
						Circle()
							.fill(.ultraThinMaterial)
						Circle()
							.fill(
								usesGradientBackground
								? AnyShapeStyle(BorealistaPalette.buttonFill)
								: AnyShapeStyle(Color.white.opacity(0.76))
							)
					}
				)
				.overlay(
					Circle()
						.stroke(Color.white.opacity(0.80), lineWidth: 1)
				)
				.shadow(color: BorealistaPalette.espresso.opacity(0.10), radius: 14, y: 8)
		}
		.buttonStyle(.plain)
	}
}

private struct TeacherScannerProgressBar: View {
	let progress: Double
	let label: String
	
	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			HStack {
				Text("Progreso")
					.font(BorealistaType.label(12))
					.foregroundStyle(BorealistaPalette.stone)
				Spacer()
				Text(label)
					.font(BorealistaType.code(12))
					.foregroundStyle(BorealistaPalette.cocoa)
			}
			
			GeometryReader { proxy in
				ZStack(alignment: .leading) {
					Capsule()
						.fill(BorealistaPalette.blush.opacity(0.16))
					
					Capsule()
						.fill(BorealistaPalette.buttonFill)
						.frame(width: proxy.size.width * max(0, min(progress, 1)))
				}
			}
			.frame(height: 10)
		}
	}
}

private struct TeacherScannerGuideOverlay: View {
	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 28, style: .continuous)
				.stroke(Color.white.opacity(0.18), lineWidth: 1)
			
			RoundedRectangle(cornerRadius: 28, style: .continuous)
				.stroke(
					Color.white.opacity(0.82),
					style: StrokeStyle(lineWidth: 2, dash: [14, 10])
				)
				.frame(width: 214, height: 214)
		}
		.padding(18)
		.allowsHitTesting(false)
	}
}

private struct TeacherScannerMockPreview: View {
	var body: some View {
		ZStack {
			LinearGradient(
				colors: [
					BorealistaPalette.ink.opacity(0.92),
					BorealistaPalette.espresso.opacity(0.98)
				],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			
			Circle()
				.fill(BorealistaPalette.cedar.opacity(0.30))
				.frame(width: 180, height: 180)
				.blur(radius: 48)
				.offset(x: 120, y: -70)
			
			Circle()
				.fill(BorealistaPalette.blush.opacity(0.24))
				.frame(width: 160, height: 160)
				.blur(radius: 58)
				.offset(x: -110, y: 110)
			
			VStack(spacing: 18) {
				ZStack {
					RoundedRectangle(cornerRadius: 24, style: .continuous)
						.fill(Color.white.opacity(0.12))
						.frame(width: 118, height: 118)
					Image(systemName: "qrcode.viewfinder")
						.font(.system(size: 42, weight: .semibold))
						.foregroundStyle(.white.opacity(0.95))
				}
				
				VStack(spacing: 6) {
					Text("Escaneo listo")
						.font(BorealistaType.heading(18))
						.foregroundStyle(.white)
					Text("Alinea el QR generado con la matricula del alumno dentro del marco.")
						.font(BorealistaType.body(13))
						.foregroundStyle(.white.opacity(0.78))
						.multilineTextAlignment(.center)
						.padding(.horizontal, 32)
				}
			}
		}
	}
}

private struct QRScannerCameraView: UIViewRepresentable {
	var isActive: Bool
	@Binding var status: TeacherScannerAvailability
	let onScanned: (String) -> Void
	
	func makeCoordinator() -> Coordinator {
		Coordinator(parent: self)
	}
	
	func makeUIView(context: Context) -> ScannerPreviewView {
		let view = ScannerPreviewView()
		context.coordinator.attachPreview(view)
		return view
	}
	
	func updateUIView(_ uiView: ScannerPreviewView, context: Context) {
		context.coordinator.parent = self
		context.coordinator.attachPreview(uiView)
		if isActive {
			context.coordinator.configureIfNeeded()
		}
		context.coordinator.setSessionActive(isActive)
	}
	
	static func dismantleUIView(_ uiView: ScannerPreviewView, coordinator: Coordinator) {
		coordinator.stopSession()
	}
	
	final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
		var parent: QRScannerCameraView
		private let session = AVCaptureSession()
		private let sessionQueue = DispatchQueue(label: "borealista.teacher.scanner")
		private weak var previewView: ScannerPreviewView?
		private var isConfigured = false
		private var lastCode = ""
		private var lastScanDate = Date.distantPast
		
		init(parent: QRScannerCameraView) {
			self.parent = parent
		}
		
		func attachPreview(_ previewView: ScannerPreviewView) {
			self.previewView = previewView
			previewView.videoPreviewLayer.session = session
		}
		
		func configureIfNeeded() {
			switch AVCaptureDevice.authorizationStatus(for: .video) {
			case .authorized:
				configureSession()
			case .notDetermined:
				DispatchQueue.main.async {
					self.parent.status = .starting
				}
				AVCaptureDevice.requestAccess(for: .video) { granted in
					DispatchQueue.main.async {
						self.parent.status = granted ? .starting : .denied
					}
					
					guard granted else {
						return
					}
					
					self.configureSession()
				}
			case .denied, .restricted:
				DispatchQueue.main.async {
					self.parent.status = .denied
				}
			@unknown default:
				DispatchQueue.main.async {
					self.parent.status = .unavailable
				}
			}
		}
		
		func setSessionActive(_ isActive: Bool) {
			guard isConfigured else {
				return
			}
			
			if isActive {
				startSession()
			} else {
				stopSession()
			}
		}
		
		func startSession() {
			sessionQueue.async {
				guard !self.session.isRunning else {
					return
				}
				
				self.session.startRunning()
			}
		}
		
		func stopSession() {
			sessionQueue.async {
				guard self.session.isRunning else {
					return
				}
				
				self.session.stopRunning()
			}
		}
		
		private func configureSession() {
			guard !isConfigured else {
				DispatchQueue.main.async {
					self.parent.status = .ready
					self.setSessionActive(self.parent.isActive)
				}
				return
			}
			
			sessionQueue.async {
				self.session.beginConfiguration()
				self.session.sessionPreset = .high
				
				guard let camera = AVCaptureDevice.default(for: .video),
							let input = try? AVCaptureDeviceInput(device: camera),
							self.session.canAddInput(input) else {
					self.session.commitConfiguration()
					DispatchQueue.main.async {
						self.parent.status = .unavailable
					}
					return
				}
				
				self.session.addInput(input)
				
				let output = AVCaptureMetadataOutput()
				guard self.session.canAddOutput(output) else {
					self.session.commitConfiguration()
					DispatchQueue.main.async {
						self.parent.status = .unavailable
					}
					return
				}
				
				self.session.addOutput(output)
				output.setMetadataObjectsDelegate(self, queue: .main)
				output.metadataObjectTypes = [.qr]
				
				self.session.commitConfiguration()
				self.isConfigured = true
				
				DispatchQueue.main.async {
					self.parent.status = .ready
					self.previewView?.videoPreviewLayer.session = self.session
					self.setSessionActive(self.parent.isActive)
				}
			}
		}
		
		func metadataOutput(
			_ output: AVCaptureMetadataOutput,
			didOutput metadataObjects: [AVMetadataObject],
			from connection: AVCaptureConnection
		) {
			guard parent.isActive,
						let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
						object.type == .qr,
						let value = object.stringValue?.trimmed,
						!value.isEmpty else {
				return
			}
			
			let now = Date()
			if value == lastCode, now.timeIntervalSince(lastScanDate) < 1.2 {
				return
			}
			
			lastCode = value
			lastScanDate = now
			parent.onScanned(value)
		}
	}
}

private final class ScannerPreviewView: UIView {
	override class var layerClass: AnyClass {
		AVCaptureVideoPreviewLayer.self
	}
	
	var videoPreviewLayer: AVCaptureVideoPreviewLayer {
		layer as! AVCaptureVideoPreviewLayer
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = .black
		videoPreviewLayer.videoGravity = .resizeAspectFill
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension Binding where Value == String {
	func asDate(format: String, localeIdentifier: String = "es_MX") -> Binding<Date> {
		Binding<Date>(
			get: {
				let stringValue = self.wrappedValue.trimmed
				let formatter = DateFormatter()
				formatter.locale = Locale(identifier: localeIdentifier)
				
				formatter.dateFormat = format
				if let date = formatter.date(from: stringValue) {
					return date
				}
				
				let fallbacks = ["yyyy-MM-dd", "d MMM yyyy", "MMM yyyy", "H:mm", "HH:mm"]
				for fallbackFormat in fallbacks {
					formatter.dateFormat = fallbackFormat
					if let date = formatter.date(from: stringValue) {
						return date
					}
				}
				
				return Date()
			},
			set: { newDate in
				let formatter = DateFormatter()
				formatter.locale = Locale(identifier: localeIdentifier)
				formatter.dateFormat = format
				self.wrappedValue = formatter.string(from: newDate)
			}
		)
	}
}


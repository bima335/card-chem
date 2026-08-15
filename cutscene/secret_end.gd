extends Control


# ============================================================
# NODE REFERENCES
# ============================================================

@onready var letter: CanvasItem = $Letter
@onready var letter_text: RichTextLabel = $Letter/LetterText


# ============================================================
# COMIC TIMELINE
# ============================================================

var step: int = -1
var timeline: Array[CanvasItem] = []


# ============================================================
# LETTER SYSTEM
# ============================================================

var is_typing: bool = false
var skip_typing: bool = false

var current_page: int = 0
var letter_pages: Array[String] = []


# ============================================================
# LETTER SETTINGS
# ============================================================

# Semakin kecil angka ini, semakin sedikit teks dalam satu halaman.
const MAX_CHARS_PER_PAGE: int = 450

const CHAR_DELAY: float = 0.025
const PUNCTUATION_DELAY: float = 0.12
const PARAGRAPH_DELAY: float = 0.35


# ============================================================
# LETTER TEXT
# ============================================================

const LETTER_TEXT: String = """
Spero...

Sudah lama sejak kamu pergi untuk menjelajahi Resonantia.

Kamu memang anak yang penurut ya, Spero.

Ayah masih ingat waktu kamu pertama kali bilang ingin pergi. Wajahmu terlihat begitu yakin, 
meskipun sebenarnya ayah tahu kamu juga takut.

Terima kasih sudah mau belajar lebih banyak.

Dan terima kasih karena selama ini sudah selalu menemani ayah. Sekarang mungkin bebanmu sudah sedikit berkurang. 
Kamu tidak perlu lagi terus memikirkan ayah setiap hari.

Maaf karena ayah tidak bisa menjelajah Resonantia bersamamu. Ayah ingin sekali melihat semua tempat yang kamu datangi. 
Mempelajari unsur yang belum pernah ayah kenal. Mendengar cerita tentang perjalananmu dan melihat apa yang kamu temukan di sana.

Tapi sepertinya ayah harus cukup mendengarnya dari cerita-cerita yang kamu bawa pulang.

Kalau kamu sedang membaca surat ini, mungkin ayah sudah tidak bersamamu.

Penyakit ini ternyata memakan waktu ayah lebih cepat dari yang ayah kira. 
Sebenarnya ayah sudah tahu sejak lama kalau waktunya tidak akan lama lagi.

Ayah hanya tidak ingin kamu mengetahuinya.

Spero, teruslah belajar.

Carilah ilmu sebanyak yang kamu bisa. Kenali dunia ini lebih jauh. Kenali setiap unsur yang kamu temui. 
Dengarkan orang-orang yang berbeda darimu dan jangan pernah takut menemukan sesuatu yang belum kamu mengerti.

Ayah hanya berharap penyakit ini berhenti sampai di sini.

Jangan biarkan apa yang terjadi pada ayah membuatmu takut pada dunia.

Justru pergilah lebih jauh.

Oh iya...

Tentang obat yang ayah ceritakan kepadamu selama ini...

Sebenarnya obat itu tidak pernah ada. hehe

Maaf karena membuatmu percaya bahwa obat itu ada.

Tapi ayah tidak pernah menyesal melihatmu pergi.

Karena tanpa obat itu, mungkin kamu tidak akan pernah melihat dunia sejauh ini.

Mungkin kamu tidak akan pernah mengenal begitu banyak unsur.

Mungkin kamu tidak akan pernah bertemu orang-orang yang berbeda.

Dan mungkin kamu tidak akan pernah belajar berdiri sendiri seperti sekarang.

Ayah ingin kamu mengerti satu hal.

Apa yang kamu kumpulkan selama perjalananmu bukanlah sekadar esensi.

Kamu telah mengumpulkan pengetahuan.

Kamu telah mengumpulkan pengalaman.

Kamu telah belajar memahami dunia yang dulu begitu asing bagimu.

Itulah yang sebenarnya ayah ingin berikan kepadamu.

Jangan pernah merasa bahwa ilmumu sudah cukup, Spero.

Dunia akan selalu memiliki sesuatu yang belum kamu ketahui.

Jangan menutup dirimu dari ilmu yang baru hanya karena kamu merasa sudah memahami semuanya.

Dan kalau suatu hari nanti kamu memiliki pengetahuan yang bisa membantu orang lain, 
jangan simpan itu hanya untuk dirimu sendiri.

Jadilah seseorang yang bisa memberikan harapan kepada orang lain.

Karena itulah alasan ayah memberimu nama Spero.

Harapan.

Ayah ingin kamu menjadi harapan.

Jadi jangan berhenti berjalan, ya.

Jangan berhenti belajar.

Dan jangan berhenti berharap.

Ayah mungkin tidak bisa menemanimu melihat Resonantia lagi.

Tapi setiap kali kamu menemukan sesuatu yang baru, 
anggap saja ayah sedang berdiri di sampingmu dan melihatnya bersamamu.

Sampai kita bertemu lagi, Spero.

Di kehidupan selanjutnya.

- Ayah
"""


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	SoundManager.play_bgm("end", 1.5) 

	# --------------------------------------------------------
	# Sembunyikan semua elemen awal
	# --------------------------------------------------------

	$Bg.hide()
	$o1.hide()
	$o2.hide()
	$o3.hide()
	$Letter.hide()


	# --------------------------------------------------------
	# Sembunyikan semua bubble
	# --------------------------------------------------------

	for child in $o1.get_children():
		if child is CanvasItem:
			child.hide()

	for child in $o2.get_children():
		if child is CanvasItem:
			child.hide()

	for child in $o3.get_children():
		if child is CanvasItem:
			child.hide()


	# --------------------------------------------------------
	# Buat timeline komik
	# --------------------------------------------------------

	timeline = [
		$Bg,

		$o1,
		$o1/b1,
		$o1/b2,
		$o1/b3,
		$o1/b4,

		$o2,
		$o2/b1,
		$o2/b2,

		$o3,
		$o3/b1,
		$o3/b2
	]


	# --------------------------------------------------------
	# Pecah surat menjadi beberapa halaman
	# --------------------------------------------------------

	letter_pages = split_letter_into_pages(LETTER_TEXT)


	# --------------------------------------------------------
	# Mulai cutscene
	# --------------------------------------------------------

	next_step()


# ============================================================
# INPUT
# ============================================================

func _input(event: InputEvent) -> void:

	var valid_input: bool = false


	# --------------------------------------------------------
	# Mouse kiri
	# --------------------------------------------------------

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			valid_input = true


	# --------------------------------------------------------
	# Keyboard Enter / Space
	# --------------------------------------------------------

	if event.is_action_pressed("ui_accept"):

		valid_input = true


	if not valid_input:

		return


	# --------------------------------------------------------
	# Kalau surat sedang mengetik
	# --------------------------------------------------------

	if is_typing:

		skip_typing = true

		return


	# --------------------------------------------------------
	# Kalau surat sudah muncul
	# --------------------------------------------------------

	if letter.visible:

		# Masih ada halaman berikutnya
		if current_page < letter_pages.size() - 1:

			current_page += 1

			show_letter_page()

		# Sudah halaman terakhir
		else:

			finish_ending()

		return


	# --------------------------------------------------------
	# Kalau masih bagian komik
	# --------------------------------------------------------

	next_step()


# ============================================================
# NEXT COMIC STEP
# ============================================================

func next_step() -> void:

	step += 1


	# --------------------------------------------------------
	# Kalau semua panel komik sudah selesai
	# --------------------------------------------------------

	if step >= timeline.size():

		show_letter()

		return


	# --------------------------------------------------------
	# Ambil node dari timeline
	# --------------------------------------------------------

	var current_item: CanvasItem = timeline[step]


	# --------------------------------------------------------
	# Tampilkan node
	# --------------------------------------------------------

	show_with_animation(current_item)


# ============================================================
# SHOW COMIC ELEMENT
# ============================================================

func show_with_animation(node: CanvasItem) -> void:

	node.show()

	node.scale = Vector2(0.8, 0.8)
	node.modulate.a = 0.0


	var tween: Tween = create_tween().set_parallel(true)


	tween.tween_property(
		node,
		"modulate:a",
		1.0,
		0.3
	)


	tween.tween_property(
		node,
		"scale",
		Vector2.ONE,
		0.4
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)




# ============================================================
# SHOW LETTER
# ============================================================

func show_letter() -> void:

	letter.show()

	letter.scale = Vector2(0.85, 0.85)
	letter.modulate.a = 0.0

	current_page = 0


	var tween: Tween = create_tween().set_parallel(true)


	tween.tween_property(
		letter,
		"modulate:a",
		1.0,
		0.8
	)


	tween.tween_property(
		letter,
		"scale",
		Vector2.ONE,
		0.8
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


	await tween.finished


	show_letter_page()


# ============================================================
# SPLIT LETTER INTO PAGES
# ============================================================

func split_letter_into_pages(full_text: String) -> Array[String]:

	var pages: Array[String] = []

	var remaining_text: String = full_text.strip_edges()


	while remaining_text.length() > 0:

		# ----------------------------------------------------
		# Kalau teks sudah cukup pendek untuk satu halaman
		# ----------------------------------------------------

		if remaining_text.length() <= MAX_CHARS_PER_PAGE:

			pages.append(remaining_text)

			break


		# ----------------------------------------------------
		# Tentukan batas karakter
		# ----------------------------------------------------

		var cut_position: int = MAX_CHARS_PER_PAGE


		# ----------------------------------------------------
		# Cari spasi terakhir sebelum batas
		# supaya tidak memotong kata
		# ----------------------------------------------------

		var last_space: int = remaining_text.rfind(
			" ",
			cut_position
		)


		# ----------------------------------------------------
		# Kalau tidak menemukan spasi
		# ----------------------------------------------------

		if last_space <= 0:

			last_space = cut_position


		# ----------------------------------------------------
		# Ambil teks halaman
		# ----------------------------------------------------

		var page_text: String = remaining_text.substr(
			0,
			last_space
		).strip_edges()


		pages.append(page_text)


		# ----------------------------------------------------
		# Buang teks halaman yang sudah diambil
		# ----------------------------------------------------

		remaining_text = remaining_text.substr(
			last_space
		).strip_edges()


	return pages


# ============================================================
# SHOW LETTER PAGE
# ============================================================

func show_letter_page() -> void:

	if current_page >= letter_pages.size():

		finish_ending()

		return


	# --------------------------------------------------------
	# Reset typing
	# --------------------------------------------------------

	is_typing = false
	skip_typing = false


	# --------------------------------------------------------
	# Set teks halaman
	# --------------------------------------------------------

	letter_text.text = letter_pages[current_page]

	letter_text.visible_characters = 0


	# --------------------------------------------------------
	# Mulai typing
	# --------------------------------------------------------

	start_letter_typing()


# ============================================================
# TYPE LETTER
# ============================================================

func start_letter_typing() -> void:

	is_typing = true
	skip_typing = false


	var current_text: String = letter_text.text


	# --------------------------------------------------------
	# Ketik satu karakter demi satu karakter
	# --------------------------------------------------------

	for i in range(current_text.length()):


		# ----------------------------------------------------
		# Kalau player melakukan skip
		# ----------------------------------------------------

		if skip_typing:

			letter_text.visible_characters = -1

			break


		# ----------------------------------------------------
		# Tampilkan karakter
		# ----------------------------------------------------

		letter_text.visible_characters = i + 1


		var current_char: String = current_text[i]


		# ----------------------------------------------------
		# Delay tanda baca
		# ----------------------------------------------------

		if (
			current_char == "."
			or current_char == ","
			or current_char == "!"
			or current_char == "?"
		):

			await get_tree().create_timer(
				PUNCTUATION_DELAY
			).timeout


		# ----------------------------------------------------
		# Delay paragraf
		# ----------------------------------------------------

		elif current_char == "\n":

			await get_tree().create_timer(
				PARAGRAPH_DELAY
			).timeout


		# ----------------------------------------------------
		# Delay karakter normal
		# ----------------------------------------------------

		else:

			await get_tree().create_timer(
				CHAR_DELAY
			).timeout


	# --------------------------------------------------------
	# Typing selesai
	# --------------------------------------------------------

	is_typing = false


# ============================================================
# FINISH ENDING
# ============================================================

func finish_ending() -> void:

	# --------------------------------------------------------
	# Tunggu sebentar
	# --------------------------------------------------------

	await get_tree().create_timer(
		2.0
	).timeout


	# --------------------------------------------------------
	# Stop BGM
	# --------------------------------------------------------

	SoundManager.stop_bgm(
		2.0
	)


	# --------------------------------------------------------
	# Tunggu fade musik
	# --------------------------------------------------------

	await get_tree().create_timer(
		2.0
	).timeout


	# --------------------------------------------------------
	# Kembali ke main menu
	# --------------------------------------------------------

	get_tree().change_scene_to_file(
		"res://main/main_menu.tscn"
	)

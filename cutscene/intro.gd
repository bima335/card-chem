extends Control

@onready var prompt_text = $PromptText 

var step = -1
var timeline = []

func _ready():
    SoundManager.play_bgm("intro_theme", 1.5) 
    
    animate_prompt_text()
    
    for child in $intro1.get_children():
        child.hide()
        child.modulate.a = 0.0 
    for child in $intro2.get_children():
        child.hide()
        child.modulate.a = 0.0 
    
    $intro1.show()
    $intro2.hide()

    timeline = [
        $intro1/Bg,
        $intro1/panel1,
        $intro1/chatbox1,
        $intro1/panel2,
        $intro1/chatbox2,
        $intro1/panel3,
        $intro1/chatbox3,
        $intro1/chatbox4,
        "GANTI_SCENE",
        $intro2/Bg,
        $intro2/panel1,
        $intro2/chatbox1,
        $intro2/chatbox2,
        $intro2/panel2,
        $intro2/chatbox3,
        $intro2/panel3,
        $intro2/chatbox4
    ]
    
    next_step()

func animate_prompt_text():
    var tween = create_tween().set_loops()
    tween.tween_property(prompt_text, "modulate:a", 0.2, 1.0)
    tween.tween_property(prompt_text, "modulate:a", 1.0, 1.0)

func _input(event):
    if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or event.is_action_pressed("ui_accept"):
        next_step()

func next_step():
    step += 1
    
    if step < timeline.size():
        var current_item = timeline[step]
        
        if typeof(current_item) == TYPE_STRING and current_item == "GANTI_SCENE":
            $intro1.hide()
            $intro2.show()
            step += 1
            current_item = timeline[step]
            show_with_animation(current_item)
            
        elif current_item is CanvasItem:
            show_with_animation(current_item)
    else:
        print("Cutscene selesai!")
        # SoundManager.stop_bgm(1.5)
        # get_tree().change_scene_to_file("res://Level1.tscn")

func show_with_animation(node: CanvasItem):
    node.show()
    
    if "Bg" in node.name:
        prompt_text.show() # Munculkan teks "click anywhere" saat layar hitam
    else:
        prompt_text.hide() # Sembunyikan teks saat panel/chatbox muncul
        SoundManager.play_sfx("card_hover", 0.1) # Mainkan SFX hanya saat panel/chatbox muncul
    
    node.scale = Vector2(0.8, 0.8)
    node.modulate.a = 0.0
    
    var tween = create_tween().set_parallel(true)
    tween.tween_property(node, "modulate:a", 1.0, 0.3)
    tween.tween_property(node, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
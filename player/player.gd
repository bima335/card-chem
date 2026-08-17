class_name Player
extends Node

signal coins_updated(oxygen: int, hydrogen: int, carbon: int, nitrogen: int)
signal stats_updated(hp: int, max_hp: int, shield: int, damage: int)
signal stun_status_changed(is_stunned: bool)

const MAX_TOKEN: int = 7

@export var oxygen: int = 0
@export var hydrogen: int = 0
@export var carbon: int = 0
@export var nitrogen: int = 0

@export var max_hp: int = GameManager.player_max_hp
var current_hp: int = GameManager.player_current_hp
var shield: int = 0
@export var base_damage: int = 0

var is_stunned: bool = false
var stun_duration: int = 0
var active_dazzle_stacks: int = 0


func _ready() -> void:
    if EventBus.has_signal("player_damage_requested"):
        if not EventBus.player_damage_requested.is_connected(take_damage):
            EventBus.player_damage_requested.connect(take_damage)
        
    if EventBus.has_signal("siphon_token_requested"):
        EventBus.siphon_token_requested.connect(_on_siphon_token_requested)
        
    if EventBus.has_signal("player_stunned_requested"):
        EventBus.player_stunned_requested.connect(apply_stun)
        
    if EventBus.has_signal("round_started"):
        EventBus.round_started.connect(_on_round_started)
        
    if EventBus.has_signal("dazzle_stacks_changed"):
        EventBus.dazzle_stacks_changed.connect(_on_dazzle_stacks_changed)

    if AuraManager.has_signal("aura_equipped"):
        AuraManager.aura_equipped.connect(_on_aura_equipped_handler)
    if AuraManager.has_signal("aura_unequipped"):
        AuraManager.aura_unequipped.connect(_on_aura_unequipped_handler)


func reset_for_battle() -> void:
    max_hp = GameManager.player_max_hp
    current_hp = GameManager.player_current_hp
    
    shield = 0
    carbon = 1
    hydrogen = 1
    oxygen = 1
    nitrogen = 1
    is_stunned = false
    stun_duration = 0
    active_dazzle_stacks = 0
    AuraManager.reset_battle_state()
    clamp_tokens_to_max()
    coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)
    stats_updated.emit(current_hp, max_hp, shield, base_damage)


func set_tokens_by_round(round_number: int) -> void:
    var old_c: int = carbon
    var old_h: int = hydrogen
    var old_o: int = oxygen
    var old_n: int = nitrogen

    carbon = clampi(round_number, 0, get_max_chn())
    hydrogen = clampi(round_number, 0, get_max_chn())
    oxygen = clampi(round_number, 0, get_max_oxygen())
    nitrogen = clampi(round_number, 0, get_max_chn())

    coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)
    
    _notify_tokens_gained({
        "Carbon": carbon - old_c,
        "Hydrogen": hydrogen - old_h,
        "Oxygen": oxygen - old_o,
        "Nitrogen": nitrogen - old_n
    })


func apply_stun(duration: int) -> void:
    is_stunned = true
    stun_duration = max(1, duration)
    stun_status_changed.emit(true)
    EventBus.player_stunned.emit(stun_duration)


func can_take_action() -> bool:
    return not is_stunned


func _on_round_started(_current_round: int) -> void:
    if is_stunned:
        stun_duration -= 1
        if stun_duration <= 0:
            is_stunned = false
            stun_duration = 0
            stun_status_changed.emit(false)


func _on_dazzle_stacks_changed(stacks: int) -> void:
    active_dazzle_stacks = stacks


func _on_aura_changed(_aura: AuraCardData = null) -> void:
    clamp_tokens_to_max()


func _on_aura_equipped_handler(_aura: AuraCardData, _slot_index: int) -> void:
    clamp_tokens_to_max()


func _on_aura_unequipped_handler(_slot_index: int) -> void:
    clamp_tokens_to_max()


func get_max_oxygen() -> int:
    return MAX_TOKEN + AuraManager.get_max_token_oxygen_modifier()


func get_max_chn() -> int:
    return MAX_TOKEN + AuraManager.get_max_token_chn_modifier()


func clamp_tokens_to_max() -> void:
    var max_o: int = get_max_oxygen()
    var max_chn: int = get_max_chn()
    
    oxygen = clampi(oxygen, 0, max_o)
    carbon = clampi(carbon, 0, max_chn)
    hydrogen = clampi(hydrogen, 0, max_chn)
    nitrogen = clampi(nitrogen, 0, max_chn)
    
    coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func get_modified_card_cost(card: CardData) -> Dictionary:
    var base_costs = {
        "carbon": card.get_effective_cost(CardData.CostType.CARBON),
        "hydrogen": card.get_effective_cost(CardData.CostType.HYDROGEN),
        "oxygen": card.get_effective_cost(CardData.CostType.OXYGEN),
        "nitrogen": card.get_effective_cost(CardData.CostType.NITROGEN)
    }
    
    if active_dazzle_stacks > 0:
        var token_keys = ["carbon", "hydrogen", "oxygen", "nitrogen"]
        for i in range(active_dazzle_stacks):
            var random_key = token_keys.pick_random()
            base_costs[random_key] += 1
            
    return base_costs


func can_afford(card: CardData) -> bool:
    if not can_take_action():
        return false
        
    var req_c = card.get_effective_cost(CardData.CostType.CARBON)
    var req_h = card.get_effective_cost(CardData.CostType.HYDROGEN)
    var req_o = card.get_effective_cost(CardData.CostType.OXYGEN)
    var req_n = card.get_effective_cost(CardData.CostType.NITROGEN)
        
    return (carbon >= req_c and hydrogen >= req_h and oxygen >= req_o and nitrogen >= req_n)


func pay_for_card(card: CardData) -> void:
    if not can_take_action():
        return
        
    var costs = get_modified_card_cost(card)
    carbon = clampi(carbon - costs["carbon"], 0, get_max_chn())
    hydrogen = clampi(hydrogen - costs["hydrogen"], 0, get_max_chn())
    oxygen = clampi(oxygen - costs["oxygen"], 0, get_max_oxygen())
    nitrogen = clampi(nitrogen - costs["nitrogen"], 0, get_max_chn())
    coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func add_tokens(c: int, h: int, o: int, n: int) -> void:
    var old_c: int = carbon
    var old_h: int = hydrogen
    var old_o: int = oxygen
    var old_n: int = nitrogen

    carbon = clampi(carbon + c, 0, get_max_chn())
    hydrogen = clampi(hydrogen + h, 0, get_max_chn())
    oxygen = clampi(oxygen + o, 0, get_max_oxygen())
    nitrogen = clampi(nitrogen + n, 0, get_max_chn())

    coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)
    
    _notify_tokens_gained({
        "Carbon": carbon - old_c,
        "Hydrogen": hydrogen - old_h,
        "Oxygen": oxygen - old_o,
        "Nitrogen": nitrogen - old_n
    })


func gain_tokens(amount: int) -> void:
    add_tokens(amount, amount, amount, amount)


func gain_shield(amount: int) -> void:
    shield += amount
    stats_updated.emit(current_hp, max_hp, shield, base_damage)


func take_damage(amount: int, attacker: EnemyBase = null) -> void:
    var result = AuraManager.process_incoming_player_damage(current_hp, shield, amount, attacker)
    
    if result["prevented"]:
        current_hp = result["new_hp"]
        shield = result["new_shield"]
    else:
        var final_incoming_damage: int = result["final_damage"]
        var actual_damage: int = final_incoming_damage - shield
        
        if actual_damage > 0:
            shield = 0
            current_hp -= actual_damage
            var calculated_intensity: float = clampf(0.3 + (float(actual_damage) / 50.0), 0.3, 0.9)
            JuiceManager.shake_camera(calculated_intensity, 0.4)
        else:
            shield -= final_incoming_damage
            JuiceManager.shake_camera(0.2, 0.15)
            
    current_hp = clampi(current_hp, 0, max_hp)
    GameManager.player_current_hp = current_hp
    stats_updated.emit(current_hp, max_hp, shield, base_damage)
    SoundManager.play_sfx("hurt")
    EventBus.player_took_damage.emit(amount)
    
    if current_hp <= 0:
        if attacker is EnemyGold:
            _handle_gold_boss_defeat()
        else:
            _trigger_game_over()


func _handle_gold_boss_defeat() -> void:
    GameManager.player_current_hp = GameManager.player_max_hp
    current_hp = max_hp
    
    GameManager.shop_coins = 0
    EventBus.gold_changed.emit(0)
    
    get_tree().paused = false
    
    var battle_scene = owner
    if battle_scene:
        battle_scene.queue_free()
        
    get_tree().change_scene_to_file("res://map/map.tscn")


func _trigger_game_over() -> void:
    get_tree().paused = true
    
    var recap_scene = load("res://ui/recap/recap_ui.tscn")
    if recap_scene:
        var recap_instance = recap_scene.instantiate() as RecapUI
        get_tree().root.add_child(recap_instance)
        recap_instance.setup_recap(false)
        var battle_scene = owner
        if battle_scene:
            battle_scene.queue_free()


func heal(amount: int) -> void:
    current_hp = clampi(current_hp + amount, 0, max_hp)
    GameManager.player_current_hp = current_hp
    stats_updated.emit(current_hp, max_hp, shield, base_damage)


func add_random_token(amount: int = 1) -> void:
    var token_types = ["carbon", "hydrogen", "oxygen", "nitrogen"]
    var chosen_token = token_types.pick_random()
    
    var gained_c: int = amount if chosen_token == "carbon" else 0
    var gained_h: int = amount if chosen_token == "hydrogen" else 0
    var gained_o: int = amount if chosen_token == "oxygen" else 0
    var gained_n: int = amount if chosen_token == "nitrogen" else 0
    
    add_tokens(gained_c, gained_h, gained_o, gained_n)


func _notify_tokens_gained(diff: Dictionary) -> void:
    var actual_gains: Dictionary = {}
    for token_name: String in diff:
        if diff[token_name] > 0:
            actual_gains[token_name] = diff[token_name]
            
    if not actual_gains.is_empty():
        EventBus.tokens_gained.emit(actual_gains)


func _on_siphon_token_requested(token_type: String, amount: int) -> void:
    match token_type:
        "oxygen":
            oxygen = max(0, oxygen - amount)
        "carbon":
            carbon = max(0, carbon - amount)
        "hydrogen":
            hydrogen = max(0, hydrogen - amount)
        "nitrogen":
            nitrogen = max(0, nitrogen - amount)
            
    coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func clean_all_debuffs() -> void:
    if is_stunned:
        is_stunned = false
        stun_duration = 0
        stun_status_changed.emit(false)

    if active_dazzle_stacks > 0:
        active_dazzle_stacks = 0
        EventBus.dazzle_stacks_changed.emit(0)
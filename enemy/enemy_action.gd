class_name EnemyAction
extends Resource

enum ActionType {ATTACK, BUFF, DEBUFF, SHIELD, HEAL}

## Nama jurus untuk ditampilkan di UI (misal: "Tebasan Brutal")
@export var action_name: String = "Serangan Biasa"

## Jenis aksinya
@export var type: ActionType = ActionType.ATTACK

## Nilai dari aksi (Damage, atau jumlah Heal/Shield)
@export var amount: int = 10

import config
import telebot
from telebot import apihelper
import csv
from peewee import *

db = SqliteDatabase('products.db')


class Product(Model):
    name = CharField()
    proteins = IntegerField()
    fats = IntegerField()
    carbohydrates = IntegerField()
    calorific = IntegerField()

    class Meta:
        database = db

    def __str__(self):
        return self.name


apihelper.proxy = {'https': 'socks5://blohinn17:blohinn17@68.183.64.161:1080'}
bot = telebot.TeleBot(config.token)


def init_db():
    Product.create_table()
    csv_path = "table_products.csv"
    with open(csv_path, "r") as file_obj:
        reader = csv.reader(file_obj)
        for ind, row in enumerate(reader):
            if ind > 0:
                row_str = "".join(row).lower()
                name, proteins, fats, carbohydrates, calorific = row_str.split(';')
                Product.create(name=name, proteins=proteins, fats=fats,
                               carbohydrates=carbohydrates, calorific=calorific)
                print(row_str)


@bot.message_handler(content_types=["text"])
def repeat_all_messages(message):
    if message.text == '/start':
        bot.send_message(message.chat.id, "Привет!\n"
                                          "Я помогу узнать и посчитать калорийность и БЖУ продуктов.\n"
                                          "Введите полное или часть названия продукта. Чтобы уточнить вес "
                                          "- через пробел введите число в граммах (по умолчанию 100). ")
        return

    message.text = message.text.strip()
    tmp = message.text.rsplit(' ', 1)
    message.text = tmp[0]
    weight = tmp[len(tmp) - 1] if len(tmp) > 1 else "100"
    if weight.isdigit():
        weight = int(weight) / 100
    else:
        weight = int(100) / 100
        for ind in range(1, len(tmp)):
            message.text += " " + tmp[ind]
    #    bot.send_message(message.chat.id, "Неправильный формат, попробуй снова!")
    #    return

    products = []
    for prod in Product.select().where(fn.Lower(fn.Substr(Product.name, 1, len(message.text))) == message.text.lower()):
        products.append(prod)

    if not products:
        bot.send_message(message.chat.id, "Продукт с именем '' не найден :(".format(message.text))
    elif len(products) == 1 or (len(products) > 1 and products[0].name in products[1].name):
        product = products[0]
        dop = ""
        if len(products) > 1:
            products = products[1:]
            dop = "\n\n Есть ещё такие продукты с похожим названием: \n{}" \
                .format(str([product.name for product in products]).replace('[', '')
                        .replace(']', '').replace(',', '\n'))

        ans = "Название продукта: {name}\n" \
              "Белки (в {weight} г.): {proteins}\n" \
              "Жиры (в {weight} г.): {fats}\n" \
              "Углеводы (в {weight} г.): {carbohydrates}\n" \
              "Калорий (в {weight} г.): {calorific}{dop}".format(weight=weight * 100,
                                                                 name=product.name,
                                                                 proteins=product.proteins * weight,
                                                                 fats=product.fats * weight,
                                                                 carbohydrates=product.carbohydrates * weight,
                                                                 calorific=product.calorific * weight,
                                                                 dop=dop)
        bot.send_message(message.chat.id, ans)
    else:
        ans = "С таким именем найдено больше одного продукта, уточните, пожалуйста:\n{}" \
            .format(str([product.name for product in products]).replace('[', '').replace(']', '').replace(',', '\n'))
        bot.send_message(message.chat.id, ans)


if __name__ == '__main__':
    # init_db()

    while True:
        try:
            bot.polling(none_stop=True)
        except Exception as e:
            print(e)


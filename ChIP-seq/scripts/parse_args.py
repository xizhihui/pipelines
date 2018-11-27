# -*- coding: utf-8 -*-
# @Author: XiZhihui
# @Date:   2018-11-24 21:43:44
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-24 22:20:32
# @Description: used for what?

def parse_args():
	import argparse

	parser = argparse.ArgumentParser()
	"""
	ArgumentParser 参数：
	prog: 程序名，sys.argv[0]
	usage: 用法，默认由参数生成
	description：在 help 项前显示的字符
	epilog: 在 help 项后显示的字符
	prefix_chars: 默认为 -
	add_help: 添加 -h/--help 选项
	"""


	# example: positional param, without a "-"
	parser.add_argument("integers", metavar="N", 
						type=int, nargs="+",
						help="an integer for the accumulator")

	# example: optional param, with '-' or '--'
	parser.add_argument("--sum",
						dest="accumulate", default=max,
						action="store_const", const=sum,
						help="sum the integers (default: find the max)")

	"""
	add_argument 参数:
	name or flags: 参数名字，一个或多个, 如 foo, -f, --foo
	action: 传入了该参数执行的动作
		store:  直接存储传入的参数
		store_const: 作为常量存储，常量值由 const 指定
		store_true/false: 作为布尔值存储
		append: 作为列表存储，如果传参多次的话，则是有多个值的列表
		append_const: 当多个参数的 dest 设为相同的话，各个参数的值存到 dest 对应的对象里
		count: 对该参数出现的次数进行计数，存储为次数
		help: 打印帮助信息，然后退出 
	nargs: 作为该参数值的参数个数，类似设为3后： -f f1 f2 f3 将获得[f1,f2,f3]
		具体的整数：捕获整数个参数作为参数值
		？：捕获 0或1次
		*：捕获所有多余的参数
		+：捕获至少 1 个多余参数
		argparse.REMAINDER: 捕获所有参数（与 * 不同在于，会捕获到未指定的 --options 名字
	const: 对于某些 action/nargs 需要的常量
	default: 未传入参数时的默认值
	type: 传入的参数的值类型, int, str, ...
	choices: 可选的参数值，传入的参数要是这里面的
	dest: 参数值存储到指定的对象
	required: 是否必须
	help: 指定帮助信息
	metavar: 显示在帮助信息中的参数名字 -f Function
	version：指定版本字符串
	"""

	# 分组参数
	group = parser.add_argument_group("group")

	# 子命令参数
	sub = parser.add_subparsers(title="subcommands",
								description="valida subcommands",
								help="additional help")
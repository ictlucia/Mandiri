import acm, ael, random
from ICTMODULES_FOR_HTML_AND_XSLFO_GENERATOR import *
from time import sleep, perf_counter

context = acm.GetDefaultContext()
today = acm.Time.DateToday()
yesterday = acm.Time.DateAddDelta(today, 0, 0, -1)
next_month = acm.Time.DateAddDelta(today, 0, 1, 0)
next_year = acm.Time.DateAddDelta(today, 1, 0, 0)
all_trades = acm.FTrade.Select("")
stand_calc = acm.FStandardCalculationsSpaceCollection()
sheet_type = "FPortfolioSheet"
calc_space = acm.Calculations().CreateCalculationSpace(context, sheet_type)
# ================ DATA FILTER COLUMN ================
dict_of_column_filter = {
    "Plain Vanilla": {
        "Product Type": ["FX"],
        "Category": ["TOD", "TOM", "SPOT", "FWD", "SWAP"],
    },
    "CCS": {"Product Type": ["SWAP"], "Category": ["CCS"]},
    "Par FWD": {"Product Type": ["SP"], "Category": ["MPF"]},
    "Surat Berharga/Fixed Income": {"Product Type": ["BOND"], "Category": ["RDPT"]},
    "IRS": {"Product Type": ["SWAP"], "Category": ["IRS"]},
    "Bond Forward": {"Product Type": ["BOND"], "Category": ["FWD"]},
    "Forward Rate Agreement": {"Product Type": ["SWAP"], "Category": ["FRA"]},
}


def final_nop_pv(obj):
    context = acm.GetDefaultContext()
    stand_calc = acm.FStandardCalculationsSpaceCollection()
    sheet_type = "FPortfolioSheet"
    calc_space = acm.Calculations().CreateCalculationSpace(context, sheet_type)
    column_id = "Final NOP Portfolio(PV)"
    try:
        return calc_space.CalculateValue(obj, column_id).Value().Number()
    except:
        return "-"


ael_gui_parameters = {
    "runButtonLabel": "&&Run",
    "hideExtraControls": True,
    "windowCaption": "SHMOa01 - NOP Limit",
}
# settings.FILE_EXTENSIONS
ael_variables = [
    ["report_name", "Report Name", "string", None, "SHMOa01 - NOP Limit", 1, 0],
    [
        "file_path",
        "Folder Path",
        getFilePathSelection(),
        None,
        getFilePathSelection(),
        1,
        1,
    ],
    [
        "output_file",
        "Secondary Output Files",
        "string",
        [".pdf", ".xls"],
        ".xls",
        0,
        1,
        "Select Secondary Extensions Output",
    ],
]


def ael_main(parameter):
    report_name = parameter["report_name"]
    file_path = str(parameter["file_path"])
    output_file = parameter["output_file"]
    fxt_ports = ael.asql("Select p.prfid from Portfolio p where p.prfid like 'FXT%'")[
        1
    ][0]
    irt_ports = ael.asql("Select p.prfid from Portfolio p where p.prfid like 'IRT%'")[
        1
    ][0]
    all_ports = fxt_ports + irt_ports
    print(all_ports)
    titles = ["", "NOP Operational", "NOP IR Related"]
    columns = []
    for ins in dict_of_column_filter.keys():
        columns.append(ins)
    columns_oper = columns[:3] + ["Total", "Limit", "%", "Status"]
    columns_ir = columns[3:] + ["Total", "Limit", "%", "Status"]
    rows = [columns_oper + columns_ir]
    for port in all_ports:
        temp_row = [port[0]]
        for ins in dict_of_column_filter.keys():
            if acm.FStoredASQLQuery[port[0] + "_" + ins] is not None:
                trd_flt = acm.FStoredASQLQuery[port[0] + "_" + ins].Query()
                nop_val = final_nop_pv(trd_flt)
                if nop_val != "-":
                    num = float(nop_val)
                    if abs(num) >= 1000.0:
                        res = (
                            "{:,.2f}".format(num)
                            .replace(",", " ")
                            .replace(".", ",")
                            .replace(" ", ".")
                        )
                    else:
                        res = "{:,.2f}".format(num).replace(".", ",")
                else:
                    res = nop_val
                temp_row.append(res)
        if len(temp_row) > 1:
            rows.append(temp_row)
        elif len(temp_row) == 1:
            rows.append(temp_row + ["-"] * len(rows[0]))
    table_html = create_html_table(titles, rows)
    for i in titles:
        if i != "":
            if "Operational" in i:
                table_html = table_html.replace(
                    "<th>" + i + "</th>",
                    '<th colspan="'
                    + str(len(columns_oper))
                    + '" style="background-color: #66ccff;">'
                    + i
                    + "</th>",
                )
            else:
                table_html = table_html.replace(
                    "<th>" + i + "</th>",
                    '<th colspan="'
                    + str(len(columns_ir))
                    + '" style="background-color: #66ccff;">'
                    + i
                    + "</th>",
                )
        else:
            table_html = table_html.replace(
                "<th>" + i + "</th>",
                '<th rowspan="2" style="background-color: #ff9966;">' + i + "</th>",
            )
    for oper in columns_oper:
        table_html = table_html.replace(
            "<td>" + oper + "</td>",
            '<td style="background-color: #66ccff;"><b>' + oper + "</b></td>",
        )
    for ir in columns_ir:
        table_html = table_html.replace(
            "<td>" + ir + "</td>",
            '<td style="background-color: #66ccff;"><b>' + ir + "</b></td>",
        )
    table_html = table_html.replace(
        "<td>FXT</td>", '<td style="text-align: left;">FXT</td>'
    )
    table_html = table_html.replace(
        "<td>IRT</td>", '<td style="text-align: left;">IRT</td>'
    )
    current_hour = get_current_hour("")
    current_date = get_current_date("")
    html_file = create_html_file(
        report_name + " " + current_date + current_hour,
        file_path,
        [table_html],
        report_name,
        current_date,
    )
    f = open(html_file, "r")
    contents = f.read().replace(
        """td, th {
      border: 1px solid #dddddd;
      text-align: center;
      padding: 8px;
    }""",
        """ td, th {
      border: 1px solid #000000;
      text-align: center;
      padding: 8px;
    }""",
    )
    f = open(html_file, "w")
    f.write(contents)
    f.close()
    f = open(html_file.replace("html", "xls"), "w")
    f.write(contents)
    f.close()
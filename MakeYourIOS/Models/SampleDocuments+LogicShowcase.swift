import Foundation

extension SampleDocuments {
    static let waterline = AppDocument(
        name: "Waterline",
        summary: "A personal hydration tracker assembled from reusable state, calculation, "
            + "control, and feedback blocks.",
        symbol: "drop.fill",
        tint: .sky,
        capabilities: [.haptics, .localStorage, .safeCalculation],
        logic: RuntimeLogic(state: [
            RuntimeStateDefinition(
                key: "water",
                type: .number,
                persistence: .project,
                initialValue: "0"
            ),
            RuntimeStateDefinition(
                key: "goal",
                type: .number,
                persistence: .project,
                initialValue: "2000"
            )
        ]),
        theme: AppVisualTheme(
            preset: .soft,
            appearance: .light,
            typography: .rounded,
            background: .gradient,
            cornerStyle: .round,
            density: .regular,
            defaultSurface: .material
        ),
        pages: [
            AppPage(
                id: "home",
                title: "Waterline",
                nodes: [
                    ComponentNode(
                        id: "water-hero",
                        kind: .hero,
                        title: "A gentler way to hydrate",
                        subtitle: "One tap at a time. Your progress stays on this iPhone.",
                        symbol: "drop.fill",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .center,
                            emphasis: .strong,
                            variant: .centered
                        )
                    ),
                    ComponentNode(
                        id: "water-total",
                        kind: .metric,
                        title: "Today",
                        subtitle: "Daily goal · {{goal}} ml",
                        symbol: "water.waves",
                        value: "{{water}} ml",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .half,
                            alignment: .center,
                            emphasis: .strong,
                            variant: .numberFirst
                        )
                    ),
                    ComponentNode(
                        id: "water-progress",
                        kind: .control,
                        title: "Daily progress",
                        subtitle: "{{water}} of {{goal}} ml",
                        symbol: "chart.bar.fill",
                        binding: "water",
                        valueBinding: "water",
                        control: RuntimeControlSpec(
                            kind: .progress,
                            minimum: 0,
                            maximum: 2_000,
                            step: 250,
                            unit: "ml"
                        ),
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .half,
                            alignment: .leading,
                            emphasis: .regular,
                            variant: .automatic
                        )
                    ),
                    quickWaterButton(
                        id: "add-water",
                        title: "Add 250 ml",
                        symbol: "plus",
                        operation: .add,
                        amount: "250",
                        condition: RuntimeCondition(
                            lhs: RuntimeOperand(source: .state, value: "water"),
                            comparison: .less,
                            rhs: RuntimeOperand(source: .literal, value: "2000")
                        ),
                        haptic: true
                    ),
                    quickWaterButton(
                        id: "remove-water",
                        title: "Remove 250 ml",
                        symbol: "minus",
                        operation: .subtract,
                        amount: "250",
                        condition: RuntimeCondition(
                            lhs: RuntimeOperand(source: .state, value: "water"),
                            comparison: .greater,
                            rhs: RuntimeOperand(source: .literal, value: "0")
                        )
                    ),
                    ComponentNode(
                        id: "reset-water",
                        kind: .button,
                        title: "Reset today",
                        symbol: "arrow.counterclockwise",
                        events: [
                            RuntimeEvent(
                                trigger: .tap,
                                steps: [
                                    RuntimeStep(
                                        kind: .setState,
                                        target: "water",
                                        expression: RuntimeExpression(
                                            operation: .literal,
                                            operands: [RuntimeOperand(source: .literal, value: "0")]
                                        ),
                                        condition: nil
                                    )
                                ]
                            )
                        ],
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .center,
                            emphasis: .subtle,
                            variant: .outlinedAction
                        )
                    ),
                    ComponentNode(
                        id: "water-privacy",
                        kind: .infoBanner,
                        title: "Built from tiny app primitives",
                        subtitle: "{{water}} ml is stored locally. The same blocks can power "
                            + "calculators, trackers, planners, and personal tools.",
                        symbol: "square.stack.3d.up.fill",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .leading,
                            emphasis: .subtle,
                            variant: .automatic
                        )
                    )
                ],
                presentation: PagePresentation(layout: .dashboard, showsNavigationTitle: false)
            )
        ]
    )

    // swiftlint:disable:next function_parameter_count
    private static func quickWaterButton(
        id: String,
        title: String,
        symbol: String,
        operation: RuntimeExpressionOperation,
        amount: String,
        condition: RuntimeCondition,
        haptic: Bool = false
    ) -> ComponentNode {
        var steps = [
            RuntimeStep(
                kind: .setState,
                target: "water",
                expression: RuntimeExpression(
                    operation: operation,
                    operands: [
                        RuntimeOperand(source: .state, value: "water"),
                        RuntimeOperand(source: .literal, value: amount)
                    ]
                ),
                condition: condition
            )
        ]
        if haptic {
            steps.append(RuntimeStep(
                kind: .playHaptic,
                target: "",
                expression: .empty,
                condition: condition
            ))
        }
        return ComponentNode(
            id: id,
            kind: .button,
            title: title,
            symbol: symbol,
            events: [RuntimeEvent(trigger: .tap, steps: steps)],
            presentation: ComponentPresentation(
                surface: .plain,
                span: .half,
                alignment: .center,
                emphasis: .regular,
                variant: haptic ? .automatic : .softAction
            )
        )
    }
}
